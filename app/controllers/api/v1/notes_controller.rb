module Api
  module V1
    class NotesController < Api::BaseController
      before_action :authorize_note_access!

      resource_description do
        short "Notes"
        description "Manage text notes"
        formats [ "json" ]
      end

      api :GET, "/notes", "List notes"
      description "Returns paginated notes with optional search."
      param_group :pagination, Api::BaseController
      param :search, String, desc: "Search notes by content", required: false
      def index
        notes_query = current_user.notes.ordered_by_date

        if params[:search].present?
          notes_query = notes_query.search(params[:search])
        end

        page = (params[:page] || 1).to_i
        per_page = (params[:per_page] || 25).to_i
        total_count = notes_query.count
        notes = notes_query.offset((page - 1) * per_page).limit(per_page)

        render json: {
          data: notes.map { |note| serialize_note(note) },
          meta: {
            page: page,
            per_page: per_page,
            total_count: total_count,
            total_pages: (total_count.to_f / per_page).ceil
          }
        }, status: :ok
      end

      api :GET, "/notes/:id", "Show a note"
      description "Returns a single note by ID."
      param :id, :number, desc: "Note ID", required: true
      def show
        note = current_user.notes.find(params[:id])

        render json: {
          data: serialize_note(note),
          meta: {}
        }, status: :ok
      rescue ActiveRecord::RecordNotFound
        render_not_found
      end

      api :POST, "/notes", "Create a note"
      description "Creates a new note, optionally attaching it to a day or item."
      param :note, Hash, desc: "Note attributes", required: true do
        param :content, String, desc: "Note content", required: true
      end
      param :day_id, :number, desc: "Day ID to attach the note to", required: false
      param :item_id, :number, desc: "Item ID to attach the note to", required: false
      def create
        note = current_user.notes.build(note_params)

        if note.save
          # Add to day or item descendant if specified
          add_to_descendant(note)

          render json: {
            data: serialize_note(note),
            meta: {}
          }, status: :created
        else
          render_error(
            note.errors.full_messages.join(", "),
            status: :unprocessable_entity,
            errors: note.errors.full_messages
          )
        end
      end

      api :PATCH, "/notes/:id", "Update a note"
      description "Updates an existing note's content."
      param :id, :number, desc: "Note ID", required: true
      param :note, Hash, desc: "Note attributes", required: true do
        param :content, String, desc: "Note content", required: false
      end
      def update
        note = current_user.notes.find(params[:id])

        if note.update(note_params)
          render json: {
            data: serialize_note(note),
            meta: {}
          }, status: :ok
        else
          render_error(
            note.errors.full_messages.join(", "),
            status: :unprocessable_entity,
            errors: note.errors.full_messages
          )
        end
      rescue ActiveRecord::RecordNotFound
        render_not_found
      end

      api :DELETE, "/notes/:id", "Delete a note"
      description "Permanently deletes a note and removes it from all parent descendants."
      param :id, :number, desc: "Note ID", required: true
      def destroy
        note = current_user.notes.find(params[:id])

        # Remove note from all descendants before destroying
        note.parent_descendants.each do |descendant|
          descendant.remove_active_record("Note", note.id)
          descendant.remove_inactive_record("Note", note.id)
          descendant.save!
        end

        note.destroy!

        render json: { data: nil, meta: {} }, status: :ok
      rescue ActiveRecord::RecordNotFound
        render_not_found
      end

      private

      def authorize_note_access!
        authorize_feature!(:notes)
      end

      def note_params
        params.require(:note).permit(:content)
      end

      def add_to_descendant(note)
        if params[:day_id].present?
          day = current_user.days.find(params[:day_id])
          day.descendant.add_active_record("Note", note.id)
          day.descendant.save!
        elsif params[:item_id].present?
          item = current_user.items.find(params[:item_id])
          descendant = item.descendant || Descendant.create!(
            descendable: item,
            active_items: [],
            inactive_items: []
          )
          descendant.add_active_record("Note", note.id)
          descendant.save!
        end
      end

      def serialize_note(note)
        {
          id: note.id,
          content: note.content,
          content_preview: note.content.truncate(200),
          created_at: note.created_at.iso8601,
          updated_at: note.updated_at.iso8601
        }
      end
    end
  end
end
