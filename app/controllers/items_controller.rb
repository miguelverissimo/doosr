# frozen_string_literal: true

class ItemsController < ApplicationController
  before_action :authenticate_user!

  def create
    @item = current_user.items.build(item_params)

    if @item.save
      # Add item to parent item's descendant if parent_item_id provided
      if params[:parent_item_id].present?
        @parent_item = current_user.items.find(params[:parent_item_id])
        @day = current_user.days.find(params[:day_id]) if params[:day_id].present?

        # Create descendant for parent if it doesn't exist
        parent_descendant = @parent_item.descendant || Descendant.create!(
          descendable: @parent_item,
          active_items: [],
          inactive_items: []
        )

        parent_descendant.add_active_item(@item.id)
        parent_descendant.save!

        respond_to do |format|
          format.turbo_stream do
            # Reload parent and its descendant to get fresh data
            @parent_item.reload
            @parent_item.descendant.reload

            # Check if this is the first child
            is_first_child = @parent_item.descendant.active_items.count == 1

            # Calculate position of new item
            active_item_ids = @parent_item.descendant.active_items
            item_index = active_item_ids.index(@item.id)

            streams = [
              # Update the nested items in the drawer
              turbo_stream.append(
                "nested_items_#{@parent_item.id}",
                render_to_string(Views::Items::DrawerChildItem.new(
                  item: @item,
                  parent_item: @parent_item,
                  day: @day,
                  item_index: item_index,
                  total_items: active_item_ids.length
                ))
              ),
              turbo_stream.update("child_item_form_errors_#{@parent_item.id}", "")
            ]

            # If this is the first child, show the "Nested items" title
            if is_first_child
              streams << turbo_stream.update(
                "nested_items_title_#{@parent_item.id}",
                "<div class='text-sm font-medium text-muted-foreground'>Nested items</div>"
              )
            end

            # Also update the parent item in the day view to show the new child
            if @day
              # Replace the entire item+children wrapper
              streams << turbo_stream.replace(
                "item_with_children_#{@parent_item.id}",
                render_to_string(Views::Items::ItemWithChildren.new(item: @parent_item, day: @day))
              )
            end

            render turbo_stream: streams
          end
          format.html { redirect_back(fallback_location: root_path, notice: "Item created") }
        end
      # Add item to day's descendant active_items array if day_id provided
      elsif params[:day_id].present?
        @day = current_user.days.find(params[:day_id])
        @day.descendant.add_active_item(@item.id)
        @day.descendant.save!

        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.append(
                "items_list",
                Views::Items::Item.new(item: @item)
              ),
              turbo_stream.update("item_form_errors", "")
            ]
          end
          format.html { redirect_back(fallback_location: root_path, notice: "Item created") }
        end
      elsif params[:date].present?
        # Create day if it doesn't exist (when adding first item)
        date = Date.parse(params[:date])
        @day = current_user.days.find_by(date: date)
        unless @day
          @day = Days::OpenDayService.new(user: current_user, date: date).call
        end
        @day.descendant.add_active_item(@item.id)
        @day.descendant.save!

        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.append(
                "items_list",
                Views::Items::Item.new(item: @item)
              ),
              turbo_stream.update("item_form_errors", "")
            ]
          end
          format.html { redirect_back(fallback_location: root_path, notice: "Item created") }
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.append(
                "items_list",
                Views::Items::Item.new(item: @item)
              ),
              turbo_stream.update("item_form_errors", "")
            ]
          end
          format.html { redirect_back(fallback_location: root_path, notice: "Item created") }
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          error_target = if params[:parent_item_id].present?
            "child_item_form_errors_#{params[:parent_item_id]}"
          else
            "item_form_errors"
          end

          render turbo_stream: turbo_stream.update(
            error_target,
            Views::Items::Errors.new(item: @item)
          )
        end
        format.html { redirect_back(fallback_location: root_path, alert: "Failed to create item") }
      end
    end
  end

  def update
    @item = current_user.items.find(params[:id])

    if @item.update(item_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "item_#{@item.id}",
            Views::Items::Item.new(item: @item)
          )
        end
        format.html { redirect_back(fallback_location: root_path, notice: "Item updated") }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "item_#{@item.id}_errors",
            Views::Items::Errors.new(item: @item)
          )
        end
        format.html { redirect_back(fallback_location: root_path, alert: "Failed to update item") }
      end
    end
  end

  def destroy
    @item = current_user.items.find(params[:id])
    @item.destroy!

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.remove("item_#{@item.id}")
      end
      format.html { redirect_back(fallback_location: root_path, notice: "Item deleted") }
    end
  end

  def actions_sheet
    @item = current_user.items.find(params[:id])
    @day = current_user.days.find(params[:day_id]) if params[:day_id].present?

    # Calculate position for disabling move buttons
    # Find which descendant (Day or Item) contains this item in its active_items
    item_index = nil
    total_items = nil

    # Find the containing descendant by checking which one has this item in active_items
    containing_descendant = Descendant.where("active_items @> ?", [@item.id].to_json).first

    if containing_descendant
      active_items = containing_descendant.active_items
      item_index = active_items.index(@item.id)
      total_items = active_items.length
    end

    respond_to do |format|
      format.turbo_stream do
        component_html = render_to_string(
          Views::Items::ActionsSheet.new(
            item: @item,
            day: @day,
            item_index: item_index,
            total_items: total_items
          )
        )
        Rails.logger.debug "Component HTML length: #{component_html.length}"
        render turbo_stream: turbo_stream.append("body", component_html)
      end
    end
  end

  def defer_options
    @item = current_user.items.find(params[:id])
    @day = current_user.days.find(params[:day_id]) if params[:day_id].present?

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "sheet_content_area",
          Views::Items::DeferOptions.new(item: @item, day: @day)
        )
      end
    end
  end

  def toggle_state
    @item = current_user.items.find(params[:id])
    new_state = params[:state]

    case new_state
    when "done"
      @item.mark_done!
    when "dropped"
      @item.mark_dropped!
    when "todo"
      @item.mark_todo!
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("item_#{@item.id}", Views::Items::Item.new(item: @item, day: find_day))
      end
      format.html { redirect_back(fallback_location: root_path) }
    end
  end

  def move
    @item = current_user.items.find(params[:id])
    @day = current_user.days.find(params[:day_id]) if params[:day_id].present?
    direction = params[:direction]

    # Find which descendant contains this item
    containing_descendant = Descendant.where("active_items @> ?", [@item.id].to_json).first

    if containing_descendant
      active_items = containing_descendant.active_items
      current_index = active_items.index(@item.id)

      if current_index
        new_index = direction == "up" ? current_index - 1 : current_index + 1

        # Only move if within bounds
        if new_index >= 0 && new_index < active_items.length
          active_items[current_index], active_items[new_index] = active_items[new_index], active_items[current_index]
          containing_descendant.active_items = active_items
          containing_descendant.save!
        end
      end

      # Determine if this is a day or item descendant
      is_day_descendant = containing_descendant.descendable_type == 'Day'
      parent_item = containing_descendant.descendable if containing_descendant.descendable_type == 'Item'
    end

    respond_to do |format|
      format.turbo_stream do
        streams = []

        if is_day_descendant && @day&.descendant
          # Re-render the entire day's items list
          active_item_ids = @day.descendant.active_items || []
          inactive_item_ids = @day.descendant.inactive_items || []
          all_item_ids = active_item_ids + inactive_item_ids
          items = Item.where(id: all_item_ids).includes(:descendant).index_by(&:id)

          rendered_items = (active_item_ids + inactive_item_ids).map do |item_id|
            next unless items[item_id]
            render_to_string(Views::Items::ItemWithChildren.new(item: items[item_id], day: @day))
          end.compact.join

          streams << turbo_stream.update("items_list", rendered_items)

          # Update action sheet buttons if it's open
          item_index = active_item_ids.index(@item.id)
          total_items = active_item_ids.length

          streams << turbo_stream.replace(
            "action_sheet_buttons_#{@item.id}",
            Views::Items::ActionsSheetButtons.new(
              item: @item,
              day: @day,
              item_index: item_index,
              total_items: total_items
            )
          )
        elsif parent_item
          # Re-render the nested items in the drawer
          parent_item.reload
          parent_item.descendant.reload

          active_item_ids = parent_item.descendant.active_items || []
          items = Item.where(id: active_item_ids).index_by(&:id)

          rendered_items = active_item_ids.map.with_index do |item_id, index|
            item = items[item_id]
            next unless item
            render_to_string(Views::Items::DrawerChildItem.new(
              item: item,
              parent_item: parent_item,
              day: @day,
              item_index: index,
              total_items: active_item_ids.length
            ))
          end.compact.join

          streams << turbo_stream.update("nested_items_#{parent_item.id}", rendered_items)

          # Update action sheet buttons if it's open
          item_index = active_item_ids.index(@item.id)
          total_items = active_item_ids.length

          streams << turbo_stream.replace(
            "action_sheet_buttons_#{@item.id}",
            Views::Items::ActionsSheetButtons.new(
              item: @item,
              day: @day,
              item_index: item_index,
              total_items: total_items
            )
          )

          # Also update the parent in the day view
          if @day
            streams << turbo_stream.replace(
              "item_with_children_#{parent_item.id}",
              render_to_string(Views::Items::ItemWithChildren.new(item: parent_item, day: @day))
            )
          end
        end

        if streams.any?
          render turbo_stream: streams
        else
          head :ok
        end
      end
      format.html { redirect_back(fallback_location: root_path) }
    end
  end

  def reparent
    @item = current_user.items.find(params[:id])
    target_item_id = params[:target_item_id]

    # Get the day from params (should always be present now)
    @day = current_user.days.find(params[:day_id]) if params[:day_id].present?

    # Find and remove item from its current descendant
    current_descendant = Descendant.where("active_items @> ? OR inactive_items @> ?", [@item.id].to_json, [@item.id].to_json).first
    if current_descendant
      current_descendant.active_items = current_descendant.active_items.reject { |id| id == @item.id }
      current_descendant.inactive_items = current_descendant.inactive_items.reject { |id| id == @item.id }
      current_descendant.save!
    end

    # Add item to target descendant
    if target_item_id.present?
      # Moving to a specific item's descendant
      target_item = current_user.items.find(target_item_id)
      target_descendant = target_item.descendant || Descendant.create!(
        descendable: target_item,
        active_items: [],
        inactive_items: []
      )

      if @item.done? || @item.dropped?
        target_descendant.inactive_items = (target_descendant.inactive_items + [@item.id]).uniq
      else
        target_descendant.active_items = (target_descendant.active_items + [@item.id]).uniq
      end
      target_descendant.save!
    else
      # Moving to root level (day's descendant)
      if @day&.descendant
        if @item.done? || @item.dropped?
          @day.descendant.inactive_items = (@day.descendant.inactive_items + [@item.id]).uniq
        else
          @day.descendant.active_items = (@day.descendant.active_items + [@item.id]).uniq
        end
        @day.descendant.save!
      end
    end

    respond_to do |format|
      format.turbo_stream do
        if @day&.descendant
          # Reload to get fresh data
          @day.reload
          @day.descendant.reload

          # Render all root-level items (active + inactive) with their nested children
          active_item_ids = @day.descendant.active_items || []
          inactive_item_ids = @day.descendant.inactive_items || []
          all_item_ids = active_item_ids + inactive_item_ids
          items = Item.includes(:descendant).where(id: all_item_ids).index_by(&:id)

          rendered_items = (active_item_ids + inactive_item_ids).map do |item_id|
            item = items[item_id]
            next unless item
            item.reload
            render_to_string(Views::Items::ItemWithChildren.new(item: item, day: @day))
          end.compact.join

          render turbo_stream: turbo_stream.update("items_list", rendered_items)
        else
          head :ok
        end
      end
      format.html { redirect_back(fallback_location: root_path, notice: "Item moved successfully") }
    end
  end

  def defer
    @item = current_user.items.find(params[:id])
    target_date_param = params[:target_date]

    # Parse target date
    target_date = case target_date_param
    when 'tomorrow'
      Item.get_tomorrow_date
    when 'next_monday'
      Item.get_next_monday_date
    when 'next_month'
      Item.get_next_month_first_date
    else
      Date.parse(target_date_param)
    end

    # Check if confirmation is needed (if item has nested items)
    if @item.has_nested_items? && params[:confirmed] != 'true'
      @day = find_day
      # Return a response indicating confirmation is needed
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "sheet_content_area",
            Views::Items::DeferConfirmation.new(
              item: @item,
              target_date: target_date,
              target_date_param: target_date_param,
              day: @day
            )
          )
        end
        format.html { redirect_back(fallback_location: root_path, alert: "Confirmation required") }
      end
      return
    end

    # Defer the item using the service
    service = ::Items::DeferService.new(
      source_item: @item,
      target_date: target_date,
      user: current_user
    )

    deferred_count = service.call

    # Find the day to refresh the UI
    @day = find_day

    respond_to do |format|
      format.turbo_stream do
        if @day&.descendant
          # Reload to get fresh data
          @day.reload
          @day.descendant.reload

          # Render all root-level items (active + inactive) with their nested children
          active_item_ids = @day.descendant.active_items || []
          inactive_item_ids = @day.descendant.inactive_items || []
          all_item_ids = active_item_ids + inactive_item_ids
          items = Item.includes(:descendant).where(id: all_item_ids).index_by(&:id)

          # Render active items first, then inactive items
          rendered_items = (active_item_ids + inactive_item_ids).map do |item_id|
            item = items[item_id]
            next unless item
            item.reload
            render_to_string(Views::Items::ItemWithChildren.new(item: item, day: @day))
          end.compact.join

          # Reload the item to get fresh state
          @item.reload

          # Calculate position for the actions sheet
          item_index = active_item_ids.index(@item.id)
          total_items = active_item_ids.length

          # Show toast and reload the actions sheet
          toast_message = "#{deferred_count} item#{deferred_count > 1 ? 's' : ''} deferred to #{target_date.strftime('%b %-d, %Y')}"

          render turbo_stream: [
            turbo_stream.update("items_list", rendered_items),
            turbo_stream.replace(
              "sheet_content_area",
              Views::Items::ActionsSheetContent.new(
                item: @item,
                day: @day,
                item_index: item_index,
                total_items: total_items
              )
            ),
            turbo_stream.append("body", "<script>window.toast && window.toast(#{toast_message.to_json}, { type: 'success' })</script>")
          ]
        else
          flash[:alert] = "Failed to defer item"
          head :ok
        end
      end
      format.html { redirect_back(fallback_location: root_path, notice: "Item deferred successfully") }
    end
  end

  def debug
    @item = current_user.items.find(params[:id])

    # Find which descendant contains this item (fix JSONB query)
    @containing_descendant = Descendant.where("active_items @> ? OR inactive_items @> ?", [@item.id].to_json, [@item.id].to_json).first
    @owner = @containing_descendant&.descendable

    respond_to do |format|
      format.turbo_stream do
        component_html = render_to_string(Views::Items::DebugSheet.new(item: @item, containing_descendant: @containing_descendant, owner: @owner))
        render turbo_stream: turbo_stream.append("body", component_html)
      end
    end
  end

  private

  def item_params
    params.require(:item).permit(:title, :item_type, :state)
  end

  def find_day
    return nil unless params[:day_id].present?
    current_user.days.find(params[:day_id])
  end
end
