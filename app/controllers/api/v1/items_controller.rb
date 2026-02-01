module Api
  module V1
    class ItemsController < Api::BaseController
      before_action :authorize_item_access!

      resource_description do
        short "Items"
        description "Manage day items (tasks, sections, etc.)"
        formats [ "json" ]
      end

      api :POST, "/items", "Create an item"
      description "Creates a new item and optionally attaches it to a day or parent item."
      param :item, Hash, desc: "Item attributes", required: true do
        param :title, String, desc: "Item title", required: true
        param :item_type, String, desc: "Item type (completable, section, reusable, trackable)", required: false
        param :state, String, desc: "Item state (todo, done, dropped, deferred)", required: false
      end
      param :day_id, :number, desc: "Day ID to attach the item to", required: false
      param :parent_item_id, :number, desc: "Parent item ID for nesting", required: false
      def create
        result = ::Items::CreateService.new(
          user: current_user,
          params: item_params,
          day_id: params[:day_id],
          parent_item_id: params[:parent_item_id]
        ).call

        if result[:success]
          render json: {
            data: serialize_item(result[:item]),
            meta: {}
          }, status: :created
        else
          render_error(result[:error], status: :unprocessable_entity)
        end
      end

      api :PATCH, "/items/:id", "Update an item"
      description "Updates an existing item's attributes."
      param :id, :number, desc: "Item ID", required: true
      param :item, Hash, desc: "Item attributes", required: true do
        param :title, String, desc: "Item title", required: false
        param :item_type, String, desc: "Item type", required: false
        param :state, String, desc: "Item state", required: false
      end
      def update
        item = current_user.items.find(params[:id])
        result = ::Items::UpdateService.new(item: item, params: item_params).call

        if result[:success]
          render json: {
            data: serialize_item(result[:item].reload),
            meta: {}
          }, status: :ok
        else
          render_error(result[:error], status: :unprocessable_entity)
        end
      rescue ActiveRecord::RecordNotFound
        render_not_found
      end

      api :DELETE, "/items/:id", "Delete an item"
      description "Permanently deletes an item."
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

      api :PATCH, "/items/:id/toggle_state", "Toggle item state"
      description "Toggles the state of an item using proper state transition methods."
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

      api :PATCH, "/items/:id/move", "Move an item"
      description "Moves an item up or down within its parent."
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

      api :PATCH, "/items/:id/defer", "Defer an item"
      description "Defers an item to a future date."
      param :id, :number, desc: "Item ID", required: true
      param :target_date, String, desc: "Target date (YYYY-MM-DD, 'tomorrow', 'next_monday', or 'next_month')", required: true
      def defer
        item = current_user.items.find(params[:id])
        target_date = parse_target_date(params[:target_date])

        unless target_date
          render_error("Invalid target date", status: :unprocessable_entity)
          return
        end

        result = ::Items::DeferService.new(
          source_item: item,
          target_date: target_date,
          user: current_user
        ).call

        if result[:success]
          render json: {
            data: serialize_item(item.reload),
            meta: { nested_items_count: result[:nested_items_count] }
          }, status: :ok
        else
          render_error(result[:error], status: :unprocessable_entity)
        end
      rescue ActiveRecord::RecordNotFound
        render_not_found
      end

      api :PATCH, "/items/:id/undefer", "Undefer an item"
      description "Removes the deferred status from an item."
      param :id, :number, desc: "Item ID", required: true
      def undefer
        item = current_user.items.find(params[:id])

        result = ::Items::UndeferService.new(
          source_item: item,
          user: current_user
        ).call

        if result[:success]
          render json: {
            data: serialize_item(item.reload),
            meta: {}
          }, status: :ok
        else
          render_error(result[:error], status: :unprocessable_entity)
        end
      rescue ActiveRecord::RecordNotFound
        render_not_found
      end

      api :PATCH, "/items/:id/reparent", "Reparent an item"
      description "Moves an item to a different parent item or day."
      param :id, :number, desc: "Item ID", required: true
      param :target_item_id, :number, desc: "Target parent item ID", required: false
      param :day_id, :number, desc: "Target day ID (moves item to day root)", required: false
      def reparent
        item = current_user.items.find(params[:id])

        target_descendant = resolve_target_descendant
        unless target_descendant
          render_error("Target not found", status: :unprocessable_entity)
          return
        end

        ::Items::ReparentService.new(item: item, target_descendant: target_descendant).call

        render json: {
          data: serialize_item(item.reload),
          meta: {}
        }, status: :ok
      rescue ActiveRecord::RecordNotFound
        render_not_found
      end

      api :PATCH, "/items/:id/drop_section", "Drop a section"
      description "Drops a section and all its child items."
      param :id, :number, desc: "Section item ID", required: true
      def drop_section
        item = current_user.items.find(params[:id])

        unless item.section?
          render_error("Only sections can be dropped with this action", status: :unprocessable_entity)
          return
        end

        result = ::Items::DropSectionService.new(section: item, user: current_user).call

        if result[:success]
          render json: {
            data: serialize_item(item.reload),
            meta: { dropped_count: result[:dropped_count] }
          }, status: :ok
        else
          render_error(result[:error], status: :unprocessable_entity)
        end
      rescue ActiveRecord::RecordNotFound
        render_not_found
      end

      api :PATCH, "/items/:id/update_recurrence", "Update item recurrence"
      description "Sets or clears the recurrence rule on an item."
      param :id, :number, desc: "Item ID", required: true
      param :recurrence_rule, String, desc: "Recurrence rule as JSON string, or 'none' to clear", required: true
      def update_recurrence
        item = current_user.items.find(params[:id])
        recurrence_rule = params[:recurrence_rule]

        if recurrence_rule.blank? || recurrence_rule == "none"
          item.update!(recurrence_rule: nil)
        else
          rule_hash = recurrence_rule.is_a?(String) ? JSON.parse(recurrence_rule) : recurrence_rule
          item.update!(recurrence_rule: rule_hash.to_json)
        end

        render json: {
          data: serialize_item(item.reload),
          meta: {}
        }, status: :ok
      rescue ActiveRecord::RecordNotFound
        render_not_found
      rescue JSON::ParserError
        render_error("Invalid recurrence rule JSON", status: :unprocessable_entity)
      end

      private

      def authorize_item_access!
        authorize_feature!(:day)
      end

      def item_params
        params.require(:item).permit(:title, :item_type, :state)
      end

      def parse_target_date(date_param)
        case date_param
        when "tomorrow"
          Item.get_tomorrow_date
        when "next_monday"
          Item.get_next_monday_date
        when "next_month"
          Item.get_next_month_first_date
        else
          Date.parse(date_param)
        end
      rescue ArgumentError, TypeError
        nil
      end

      def resolve_target_descendant
        if params[:target_item_id].present?
          target_item = current_user.items.find(params[:target_item_id])
          target_item.descendant || Descendant.create!(
            descendable: target_item,
            active_items: [],
            inactive_items: []
          )
        elsif params[:day_id].present?
          day = current_user.days.find(params[:day_id])
          day.descendant
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
