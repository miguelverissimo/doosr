# frozen_string_literal: true

class ItemsController < ApplicationController
  before_action :authenticate_user!

  def create
    @item = current_user.items.build(item_params)

    if @item.save
      # Add item to day's descendant active_items array if day_id provided
      if params[:day_id].present?
        @day = current_user.days.find(params[:day_id])
        @day.descendant.add_active_item(@item.id)
        @day.descendant.save!
      end

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
          render turbo_stream: turbo_stream.update(
            "item_form_errors",
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

    respond_to do |format|
      format.turbo_stream do
        component_html = render_to_string(Views::Items::ActionsSheet.new(item: @item, day: @day))
        Rails.logger.debug "Component HTML length: #{component_html.length}"
        render turbo_stream: turbo_stream.append("body", component_html)
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

    if @day&.descendant
      descendant = @day.descendant
      active_items = descendant.active_items
      current_index = active_items.index(@item.id)

      if current_index
        new_index = direction == "up" ? current_index - 1 : current_index + 1

        # Only move if within bounds
        if new_index >= 0 && new_index < active_items.length
          active_items[current_index], active_items[new_index] = active_items[new_index], active_items[current_index]
          descendant.active_items = active_items
          descendant.save!
        end
      end
    end

    respond_to do |format|
      format.turbo_stream do
        # Re-render the entire items list to show new order
        items = Item.where(id: @day.descendant.active_items).index_by(&:id)
        render turbo_stream: turbo_stream.update("items_list") do
          @day.descendant.active_items.map do |item_id|
            Views::Items::Item.new(item: items[item_id], day: @day).call if items[item_id]
          end.join.html_safe
        end
      end
      format.html { redirect_back(fallback_location: root_path) }
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
