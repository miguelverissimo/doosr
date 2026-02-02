module Api
  module V1
    class ListItemsController < Api::BaseController
      before_action :authorize_list_access!
      before_action :set_list

      resource_description do
        short "List Items"
        description "Manage items within a list"
        meta group: "Tasks & Planning"
        formats [ "json" ]
      end

      api :POST, "/lists/:list_id/items", "Create a list item"
      description "Creates a new item in a list. Only reusable or section items allowed. Detects duplicates."
      param :list_id, :number, desc: "List ID", required: true
      param :item, Hash, desc: "Item attributes", required: true do
        param :title, String, desc: "Item title", required: true
        param :item_type, String, desc: "Item type (reusable, section)", required: false
        param :state, String, desc: "Item state", required: false
      end
      def create
        item = current_user.items.build(item_params)

        unless item.reusable? || item.section?
          render_error("Lists can only contain 'reusable' or 'section' items", status: :unprocessable_entity)
          return
        end

        # Check for duplicates (reusable items only)
        if item.reusable?
          existing = find_duplicate_in_list(item.title)
          if existing
            handle_existing_item(existing)
            return
          end
        end

        unless item.save
          render_error(
            item.errors.full_messages.join(", "),
            status: :unprocessable_entity,
            errors: item.errors.full_messages
          )
          return
        end

        @list.descendant.add_active_item(item.id)
        @list.descendant.save!

        render json: {
          data: serialize_item(item),
          meta: {}
        }, status: :created
      end

      api :PATCH, "/lists/:list_id/items/:id", "Update a list item"
      description "Updates an existing item in a list."
      param :list_id, :number, desc: "List ID", required: true
      param :id, :number, desc: "Item ID", required: true
      param :item, Hash, desc: "Item attributes", required: true do
        param :title, String, desc: "Item title", required: false
        param :item_type, String, desc: "Item type (reusable, section)", required: false
        param :state, String, desc: "Item state", required: false
      end
      def update
        item = current_user.items.find(params[:id])

        if params.dig(:item, :item_type).present?
          new_type = params.dig(:item, :item_type)
          unless new_type == "reusable" || new_type == "section"
            render_error("Lists can only contain 'reusable' or 'section' items", status: :unprocessable_entity)
            return
          end
        end

        if item.update(item_params)
          render json: {
            data: serialize_item(item.reload),
            meta: {}
          }, status: :ok
        else
          render_error(
            item.errors.full_messages.join(", "),
            status: :unprocessable_entity,
            errors: item.errors.full_messages
          )
        end
      rescue ActiveRecord::RecordNotFound
        render_not_found
      end

      api :DELETE, "/lists/:list_id/items/:id", "Delete a list item"
      description "Permanently deletes an item from a list."
      param :list_id, :number, desc: "List ID", required: true
      param :id, :number, desc: "Item ID", required: true
      def destroy
        item = current_user.items.find(params[:id])

        result = ::Items::DestroyService.new(item: item).call

        if result[:success]
          render json: { data: nil, meta: {} }, status: :ok
        else
          render_error(result[:error], status: :unprocessable_entity)
        end
      rescue ActiveRecord::RecordNotFound
        render_not_found
      end

      api :PATCH, "/lists/:list_id/items/:id/toggle_state", "Toggle item state"
      description "Toggles the state of a list item (todo/done/dropped)."
      param :list_id, :number, desc: "List ID", required: true
      param :id, :number, desc: "Item ID", required: true
      param :state, String, desc: "Target state (todo, done, dropped)", required: true
      def toggle_state
        item = current_user.items.find(params[:id])
        result = ::Items::ToggleStateService.new(item: item, new_state: params[:state]).call

        if result[:success]
          render json: {
            data: serialize_item(result[:item]),
            meta: {}
          }, status: :ok
        else
          render_error(result[:error], status: :unprocessable_entity)
        end
      rescue ActiveRecord::RecordNotFound
        render_not_found
      end

      api :PATCH, "/lists/:list_id/items/:id/move", "Move a list item"
      description "Moves an item up or down within its list."
      param :list_id, :number, desc: "List ID", required: true
      param :id, :number, desc: "Item ID", required: true
      param :direction, String, desc: "Direction to move (up, down)", required: true
      def move
        item = current_user.items.find(params[:id])
        result = ::Items::MoveService.new(item: item, direction: params[:direction]).call

        if result[:success]
          render json: {
            data: serialize_item(result[:item]),
            meta: {}
          }, status: :ok
        else
          render_error(result[:error], status: :unprocessable_entity)
        end
      rescue ActiveRecord::RecordNotFound
        render_not_found
      end

      api :PATCH, "/lists/:list_id/items/:id/reparent", "Reparent a list item"
      description "Moves an item to a different parent within the list."
      param :list_id, :number, desc: "List ID", required: true
      param :id, :number, desc: "Item ID", required: true
      param :target_item_id, :number, desc: "Target parent item ID (omit to move to list root)", required: false
      def reparent
        item = current_user.items.find(params[:id])

        target_descendant = if params[:target_item_id].present?
          target_item = current_user.items.find(params[:target_item_id])
          target_item.descendant || Descendant.create!(
            descendable: target_item,
            active_items: [],
            inactive_items: []
          )
        else
          @list.descendant
        end

        ::Items::ReparentService.new(item: item, target_descendant: target_descendant).call

        render json: {
          data: serialize_item(item.reload),
          meta: {}
        }, status: :ok
      rescue ActiveRecord::RecordNotFound
        render_not_found
      end

      private

      def authorize_list_access!
        authorize_feature!(:lists)
      end

      def set_list
        @list = current_user.lists.find(params[:list_id])
      rescue ActiveRecord::RecordNotFound
        render_not_found
      end

      def item_params
        params.require(:item).permit(:title, :item_type, :state)
      end

      def find_duplicate_in_list(title)
        return nil unless @list.descendant

        item_ids = @list.descendant.extract_active_item_ids + @list.descendant.extract_inactive_item_ids
        return nil if item_ids.empty?

        Item.where(id: item_ids).find do |item|
          item.title.downcase == title.downcase && item.reusable?
        end
      end

      def handle_existing_item(existing_item)
        containing_descendant = Descendant.containing_item(existing_item.id)

        if containing_descendant&.active_item?(existing_item.id)
          render json: {
            data: serialize_item(existing_item),
            meta: { duplicate: true, message: "#{existing_item.title} already in list" }
          }, status: :ok
        else
          existing_item.set_todo!
          render json: {
            data: serialize_item(existing_item.reload),
            meta: { reactivated: true, message: "#{existing_item.title} marked as todo" }
          }, status: :ok
        end
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
