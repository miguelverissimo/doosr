module Api
  module V1
    class JournalsController < Api::BaseController
      before_action :authorize_journal_access!

      resource_description do
        short "Journals"
        description "Manage daily journal entries"
        formats [ "json" ]
      end

      api :GET, "/journals", "List journals"
      description "Returns paginated journals with optional date search."
      param_group :pagination, Api::BaseController
      param :search, String, desc: "Search journals by date", required: false
      def index
        page = (params[:page] || 1).to_i
        per_page = (params[:per_page] || 25).to_i

        journals_query = current_user.journals.ordered_by_date

        if params[:search].present?
          journals_query = journals_query.search_by_date(params[:search])
        end

        total_count = journals_query.count
        journals = journals_query.offset((page - 1) * per_page).limit(per_page)

        render json: {
          data: journals.map { |j| serialize_journal(j) },
          meta: {
            page: page,
            per_page: per_page,
            total_count: total_count,
            total_pages: (total_count.to_f / per_page).ceil
          }
        }, status: :ok
      end

      api :GET, "/journals/:id", "Show a journal"
      description "Returns a single journal with its fragments and prompts."
      param :id, :number, desc: "Journal ID", required: true
      def show
        journal = current_user.journals.find(params[:id])

        render json: {
          data: serialize_journal_with_content(journal),
          meta: {}
        }, status: :ok
      rescue ActiveRecord::RecordNotFound
        render_not_found
      end

      api :POST, "/journals", "Create a journal"
      description "Creates a new journal entry for a given date. Auto-creates scheduled prompts."
      param :journal, Hash, desc: "Journal attributes", required: true do
        param :date, String, desc: "Journal date (YYYY-MM-DD)", required: true
      end
      def create
        journal = current_user.journals.build(journal_params)

        if journal.save
          # Auto-create scheduled prompts
          ::Journals::OpenOrCreateService.call(user: current_user, date: journal.date)
          journal.reload

          render json: {
            data: serialize_journal_with_content(journal),
            meta: {}
          }, status: :created
        else
          render_error(
            journal.errors.full_messages.join(", "),
            status: :unprocessable_entity,
            errors: journal.errors.full_messages
          )
        end
      end

      api :DELETE, "/journals/:id", "Delete a journal"
      description "Permanently deletes a journal and removes it from all parent descendants."
      param :id, :number, desc: "Journal ID", required: true
      def destroy
        journal = current_user.journals.find(params[:id])

        # Remove from all parent descendants before destroying
        journal.parent_descendants.each do |descendant|
          descendant.remove_active_record("Journal", journal.id)
          descendant.remove_inactive_record("Journal", journal.id)
          descendant.save!
        end

        journal.destroy!

        render json: { data: nil, meta: {} }, status: :ok
      rescue ActiveRecord::RecordNotFound
        render_not_found
      end

      private

      def authorize_journal_access!
        authorize_feature!(:journals)
      end

      def journal_params
        params.require(:journal).permit(:date)
      end

      def serialize_journal(journal)
        {
          id: journal.id,
          date: journal.date.to_s,
          date_display: journal.date_display,
          attached: journal.attached?,
          created_at: journal.created_at.iso8601,
          updated_at: journal.updated_at.iso8601
        }
      end

      def serialize_journal_with_content(journal)
        data = serialize_journal(journal)

        # Include fragments
        data[:fragments] = journal.journal_fragments.order(:created_at).map do |fragment|
          {
            id: fragment.id,
            content: fragment.content,
            created_at: fragment.created_at.iso8601,
            updated_at: fragment.updated_at.iso8601
          }
        end

        # Include prompts
        data[:prompts] = journal.journal_prompts.order(:created_at).map do |prompt|
          {
            id: prompt.id,
            prompt_text: prompt.prompt_text,
            created_at: prompt.created_at.iso8601
          }
        end

        data
      end
    end
  end
end
