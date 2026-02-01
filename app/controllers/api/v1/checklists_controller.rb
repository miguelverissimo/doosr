module Api
  module V1
    class ChecklistsController < Api::BaseController
      before_action :authorize_checklist_access!

      resource_description do
        short "Checklists"
        description "Manage checklists with completable items"
        formats [ "json" ]
      end

      api :GET, "/checklists", "List all checklists"
      description "Returns all checklists for the authenticated user."
      def index
        checklists = current_user.checklists.order(created_at: :desc)

        render json: {
          data: checklists.map { |cl| serialize_checklist(cl) },
          meta: { total_count: checklists.count }
        }, status: :ok
      end

      api :GET, "/checklists/:id", "Show a checklist"
      description "Returns a single checklist with its items and metadata."
      param :id, :number, desc: "Checklist ID", required: true
      def show
        checklist = current_user.checklists.find(params[:id])

        render json: {
          data: serialize_checklist(checklist),
          meta: {}
        }, status: :ok
      rescue ActiveRecord::RecordNotFound
        render_not_found
      end

      api :POST, "/checklists", "Create a checklist"
      description "Creates a new checklist."
      param :checklist, Hash, desc: "Checklist attributes", required: true do
        param :name, String, desc: "Checklist name", required: true
        param :description, String, desc: "Checklist description", required: false
        param :kind, String, desc: "Checklist kind", required: false
        param :flow, String, desc: "Checklist flow", required: false
        param :items, Array, desc: "Array of checklist items" do
          param :name, String, desc: "Item name", required: true
          param :completed_at, String, desc: "Completion timestamp (ISO 8601)", required: false
        end
        param :metadata, Hash, desc: "Checklist metadata", required: false
      end
      def create
        checklist = current_user.checklists.build(checklist_params)

        if checklist.save
          render json: {
            data: serialize_checklist(checklist),
            meta: {}
          }, status: :created
        else
          render_error(
            checklist.errors.full_messages.join(", "),
            status: :unprocessable_entity,
            errors: checklist.errors.full_messages
          )
        end
      end

      api :PATCH, "/checklists/:id", "Update a checklist"
      description "Updates an existing checklist."
      param :id, :number, desc: "Checklist ID", required: true
      param :checklist, Hash, desc: "Checklist attributes", required: true do
        param :name, String, desc: "Checklist name", required: false
        param :description, String, desc: "Checklist description", required: false
        param :kind, String, desc: "Checklist kind", required: false
        param :flow, String, desc: "Checklist flow", required: false
        param :items, Array, desc: "Array of checklist items" do
          param :name, String, desc: "Item name", required: true
          param :completed_at, String, desc: "Completion timestamp (ISO 8601)", required: false
        end
        param :metadata, Hash, desc: "Checklist metadata", required: false
      end
      def update
        checklist = current_user.checklists.find(params[:id])

        if checklist.update(checklist_params)
          render json: {
            data: serialize_checklist(checklist),
            meta: {}
          }, status: :ok
        else
          render_error(
            checklist.errors.full_messages.join(", "),
            status: :unprocessable_entity,
            errors: checklist.errors.full_messages
          )
        end
      rescue ActiveRecord::RecordNotFound
        render_not_found
      end

      api :DELETE, "/checklists/:id", "Delete a checklist"
      description "Permanently deletes a checklist."
      param :id, :number, desc: "Checklist ID", required: true
      def destroy
        checklist = current_user.checklists.find(params[:id])
        checklist.destroy!

        render json: { data: nil, meta: {} }, status: :ok
      rescue ActiveRecord::RecordNotFound
        render_not_found
      end

      api :PATCH, "/checklists/:id/complete_item", "Toggle a checklist item's completion"
      description "Toggles the completed_at timestamp on a checklist item by index."
      param :id, :number, desc: "Checklist ID", required: true
      param :item_index, :number, desc: "Zero-based index of the item to toggle", required: true
      def complete_item
        checklist = current_user.checklists.find(params[:id])
        item_index = params[:item_index].to_i
        items = checklist.items.dup

        unless items[item_index]
          render_error("Item not found at index #{item_index}", status: :unprocessable_entity)
          return
        end

        item = items[item_index]
        if item["completed_at"].present?
          item["completed_at"] = nil
        else
          item["completed_at"] = Time.current.iso8601
        end
        items[item_index] = item

        metadata = checklist.metadata.dup
        completed_count = items.count { |i| i["completed_at"].present? }
        metadata["started_at"] ||= Time.current.iso8601 if completed_count > 0

        if completed_count == items.length
          metadata["completed_at"] = Time.current.iso8601
        else
          metadata["completed_at"] = nil
        end

        checklist.update!(items: items, metadata: metadata)

        render json: {
          data: serialize_checklist(checklist),
          meta: {}
        }, status: :ok
      rescue ActiveRecord::RecordNotFound
        render_not_found
      end

      api :POST, "/checklists/:id/reset", "Reset a checklist"
      description "Clears all completion timestamps and resets metadata."
      param :id, :number, desc: "Checklist ID", required: true
      def reset
        checklist = current_user.checklists.find(params[:id])
        items = checklist.items.dup
        items.each { |item| item["completed_at"] = nil }

        metadata = checklist.metadata.dup
        metadata["started_at"] = nil
        metadata["completed_at"] = nil

        checklist.update!(items: items, metadata: metadata)

        render json: {
          data: serialize_checklist(checklist),
          meta: {}
        }, status: :ok
      rescue ActiveRecord::RecordNotFound
        render_not_found
      end

      private

      def authorize_checklist_access!
        authorize_feature!(:checklists)
      end

      def checklist_params
        params.require(:checklist).permit(:name, :description, :kind, :flow, items: [ :name, :completed_at ], metadata: {})
      end

      def serialize_checklist(checklist)
        {
          id: checklist.id,
          name: checklist.name,
          description: checklist.description,
          kind: checklist.kind,
          flow: checklist.flow,
          items: checklist.items,
          metadata: checklist.metadata,
          created_at: checklist.created_at.iso8601,
          updated_at: checklist.updated_at.iso8601
        }
      end
    end
  end
end
