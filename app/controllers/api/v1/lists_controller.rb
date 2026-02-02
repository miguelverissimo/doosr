module Api
  module V1
    class ListsController < Api::BaseController
      before_action :authorize_list_access!

      resource_description do
        short "Lists"
        description "Manage reusable item lists"
        meta group: "Tasks & Planning"
        formats [ "json" ]
      end

      api :GET, "/lists", "List all lists"
      description "Returns all lists for the authenticated user, ordered by creation date descending."
      def index
        lists = current_user.lists.order(created_at: :desc)

        render json: {
          data: lists.map { |list| serialize_list(list) },
          meta: { total_count: lists.count }
        }, status: :ok
      end

      api :GET, "/lists/:id", "Show a list"
      description "Returns a single list with its active and inactive items."
      param :id, :number, desc: "List ID", required: true
      def show
        list = current_user.lists.find(params[:id])

        render json: {
          data: serialize_list_with_items(list),
          meta: {}
        }, status: :ok
      rescue ActiveRecord::RecordNotFound
        render_not_found
      end

      api :POST, "/lists", "Create a list"
      description "Creates a new list."
      param :list, Hash, desc: "List attributes", required: true do
        param :title, String, desc: "List title", required: true
        param :list_type, String, desc: "List type", required: false
        param :visibility, String, desc: "Visibility (private_list, public_list, shared_list)", required: false
        param :slug, String, desc: "URL slug for public lists", required: false
      end
      def create
        list = current_user.lists.build(list_params)

        if list.save
          render json: {
            data: serialize_list(list),
            meta: {}
          }, status: :created
        else
          render_error(
            list.errors.full_messages.join(", "),
            status: :unprocessable_entity,
            errors: list.errors.full_messages
          )
        end
      end

      api :PATCH, "/lists/:id", "Update a list"
      description "Updates an existing list."
      param :id, :number, desc: "List ID", required: true
      param :list, Hash, desc: "List attributes", required: true do
        param :title, String, desc: "List title", required: false
        param :list_type, String, desc: "List type", required: false
        param :visibility, String, desc: "Visibility (private_list, public_list, shared_list)", required: false
        param :slug, String, desc: "URL slug for public lists", required: false
      end
      def update
        list = current_user.lists.find(params[:id])

        if list.update(list_params)
          render json: {
            data: serialize_list(list),
            meta: {}
          }, status: :ok
        else
          render_error(
            list.errors.full_messages.join(", "),
            status: :unprocessable_entity,
            errors: list.errors.full_messages
          )
        end
      rescue ActiveRecord::RecordNotFound
        render_not_found
      end

      api :DELETE, "/lists/:id", "Delete a list"
      description "Permanently deletes a list and its items."
      param :id, :number, desc: "List ID", required: true
      def destroy
        list = current_user.lists.find(params[:id])
        list.destroy!

        render json: { data: nil, meta: {} }, status: :ok
      rescue ActiveRecord::RecordNotFound
        render_not_found
      end

      private

      def authorize_list_access!
        authorize_feature!(:lists)
      end

      def list_params
        params.require(:list).permit(:title, :list_type, :visibility, :slug)
      end

      def serialize_list(list)
        {
          id: list.id,
          title: list.title,
          slug: list.slug,
          list_type: list.list_type,
          visibility: list.visibility,
          created_at: list.created_at.iso8601,
          updated_at: list.updated_at.iso8601
        }
      end

      def serialize_list_with_items(list)
        data = serialize_list(list)

        if list.descendant
          active_item_ids = list.descendant.extract_active_item_ids
          inactive_item_ids = list.descendant.extract_inactive_item_ids

          active_items = active_item_ids.any? ? Item.where(id: active_item_ids).index_by(&:id) : {}
          inactive_items = inactive_item_ids.any? ? Item.where(id: inactive_item_ids).index_by(&:id) : {}

          data[:items] = active_item_ids.filter_map { |id| serialize_item(active_items[id]) if active_items[id] }
          data[:inactive_items] = inactive_item_ids.filter_map { |id| serialize_item(inactive_items[id]) if inactive_items[id] }
        else
          data[:items] = []
          data[:inactive_items] = []
        end

        data
      end

      def serialize_item(item)
        {
          id: item.id,
          title: item.title,
          item_type: item.item_type,
          state: item.state,
          deferred_to: item.deferred_to&.to_s,
          recurrence_rule: item.recurrence_rule,
          created_at: item.created_at.iso8601,
          updated_at: item.updated_at.iso8601
        }
      end
    end
  end
end
