# frozen_string_literal: true

class DayListLinksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_list_and_day, only: [ :destroy, :actions_sheet, :move, :reparent, :debug ]

  # POST /day_list_links
  # Params: list_id, day_id
  def create
    @list = current_user.lists.find(params[:list_id])
    @day = current_user.days.find(params[:day_id])

    # Check if list already linked
    if @day.descendant.active_record?("List", @list.id)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(
            "body",
            "<script>window.toast && window.toast('List already linked to this day', { type: 'warning' })</script>"
          )
        end
      end
      return
    end

    # Add list to day's descendant
    @day.descendant.add_active_record("List", @list.id)
    @day.descendant.save!

    respond_to do |format|
      format.turbo_stream do
        # Rebuild day's item tree
        tree = ItemTree::Build.call(@day.descendant, root_label: "day")
        rendered_items = tree.children.map do |node|
          render_to_string(Views::Items::TreeNode.new(node: node, day: @day))
        end.join

        render turbo_stream: [
          turbo_stream.update("items_list", rendered_items),
          turbo_stream.append("body", "<script>window.toast && window.toast('List link added', { type: 'success' })</script>")
        ]
      end
    end
  end

  # DELETE /day_list_links/:id
  # :id is the list_id
  def destroy
    # Remove list from day's descendant
    @day.descendant.remove_active_record("List", @list.id)
    @day.descendant.save!

    respond_to do |format|
      format.turbo_stream do
        # Rebuild and close drawer
        tree = ItemTree::Build.call(@day.descendant, root_label: "day")
        rendered_items = tree.children.map do |node|
          render_to_string(Views::Items::TreeNode.new(node: node, day: @day))
        end.join

        render turbo_stream: [
          turbo_stream.update("items_list", rendered_items),
          turbo_stream.remove("actions_sheet"),
          turbo_stream.append("body", "<script>window.toast && window.toast('List link removed', { type: 'success' })</script>")
        ]
      end
    end
  end

  # GET /day_list_links/:id/actions
  def actions_sheet
    # Calculate position for move buttons
    tuple = { "List" => @list.id }
    containing_descendant = @day.descendant

    if containing_descendant
      active_tuples = containing_descendant.active_items
      item_index = active_tuples.index(tuple)
      total_items = active_tuples.length
    end

    respond_to do |format|
      format.turbo_stream do
        component_html = render_to_string(Views::DayListLinks::ActionsSheet.new(
          list: @list,
          day: @day,
          item_index: item_index,
          total_items: total_items
        ))
        render turbo_stream: turbo_stream.append("body", component_html)
      end
    end
  end

  # PATCH /day_list_links/:id/move
  # Params: direction (up/down)
  def move
    direction = params[:direction]
    tuple = { "List" => @list.id }
    descendant = @day.descendant
    active_tuples = descendant.active_items
    current_index = active_tuples.index(tuple)

    if current_index
      new_index = direction == "up" ? current_index - 1 : current_index + 1

      if new_index >= 0 && new_index < active_tuples.length
        active_tuples[current_index], active_tuples[new_index] =
          active_tuples[new_index], active_tuples[current_index]
        descendant.active_items = active_tuples
        descendant.save!
      end
    end

    # Re-render day items
    respond_to do |format|
      format.turbo_stream do
        tree = ItemTree::Build.call(@day.descendant, root_label: "day")
        rendered_items = tree.children.map do |node|
          render_to_string(Views::Items::TreeNode.new(node: node, day: @day))
        end.join

        # Also update action sheet buttons with new position
        new_index_position = descendant.active_items.index(tuple)

        render turbo_stream: [
          turbo_stream.update("items_list", rendered_items),
          turbo_stream.replace(
            "action_sheet_buttons_list_#{@list.id}",
            render_to_string(Views::DayListLinks::ActionButtons.new(
              list: @list,
              day: @day,
              item_index: new_index_position,
              total_items: active_tuples.length
            ))
          )
        ]
      end
    end
  end

  # PATCH /day_list_links/:id/reparent
  # Params: target_item_id (optional - nil means move to root)
  def reparent
    target_item_id = params[:target_item_id]

    # For now, just show a toast (full implementation would be similar to ItemsController#reparent)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(
          "body",
          "<script>window.toast && window.toast('Reparent not yet implemented for list links', { type: 'info' })</script>"
        )
      end
    end
  end

  # GET /day_list_links/:id/debug
  def debug
    # Debug info for development
    containing_descendant = @day.descendant

    respond_to do |format|
      format.turbo_stream do
        component_html = render_to_string(Views::DayListLinks::DebugSheet.new(
          list: @list,
          day: @day,
          containing_descendant: containing_descendant
        ))
        render turbo_stream: turbo_stream.append("body", component_html)
      end
    end
  end

  private

  def set_list_and_day
    @list = current_user.lists.find(params[:id])
    @day = current_user.days.find(params[:day_id])
  end
end
