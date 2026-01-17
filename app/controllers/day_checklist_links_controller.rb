# frozen_string_literal: true

class DayChecklistLinksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_checklist_and_day, only: [ :destroy, :actions_sheet, :move, :reparent, :debug ]

  # POST /day_checklist_links
  # Params: template_id, day_id
  def create
    @template = current_user.checklists.template.find(params[:template_id])
    @day = current_user.days.find(params[:day_id])

    # Check if this template is already linked to the day
    existing_checklist_ids = @day.descendant.extract_active_ids_by_type("Checklist") +
                              @day.descendant.extract_inactive_ids_by_type("Checklist")

    existing_checklist = current_user.checklists
      .where(template_id: @template.id)
      .where(id: existing_checklist_ids)
      .first

    if existing_checklist
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(
            "body",
            "<script>window.toast && window.toast('This checklist is already linked to this day', { type: 'warning' })</script>"
          )
        end
      end
      return
    end

    # Create checklist instance from template
    @checklist = current_user.checklists.create!(
      kind: :checklist,
      name: @template.name,
      description: @template.description,
      flow: @template.flow,
      items: @template.items.dup,
      metadata: {},
      template: @template
    )

    # Add checklist to day's descendant (at the beginning)
    @day.descendant.prepend_active_record("Checklist", @checklist.id)
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
          turbo_stream.append("body", "<script>window.toast && window.toast('Checklist added', { type: 'success' })</script>")
        ]
      end
    end
  end

  # DELETE /day_checklist_links/:id
  # :id is the checklist_id
  def destroy
    # Remove checklist from day's descendant
    @day.descendant.remove_active_record("Checklist", @checklist.id)
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
          turbo_stream.append("body", "<script>window.toast && window.toast('Checklist removed', { type: 'success' })</script>")
        ]
      end
    end
  end

  # GET /day_checklist_links/:id/actions
  def actions_sheet
    # Calculate position for move buttons
    tuple = { "Checklist" => @checklist.id }
    containing_descendant = @day.descendant

    if containing_descendant
      active_tuples = containing_descendant.active_items
      item_index = active_tuples.index(tuple)
      total_items = active_tuples.length
    end

    respond_to do |format|
      format.turbo_stream do
        component_html = render_to_string(Views::DayChecklistLinks::ActionsSheet.new(
          checklist: @checklist,
          day: @day,
          item_index: item_index,
          total_items: total_items
        ))
        render turbo_stream: turbo_stream.append("body", component_html)
      end
    end
  end

  # PATCH /day_checklist_links/:id/move
  # Params: direction (up/down)
  def move
    direction = params[:direction]
    tuple = { "Checklist" => @checklist.id }
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
            "action_sheet_buttons_checklist_#{@checklist.id}",
            render_to_string(Views::DayChecklistLinks::ActionButtons.new(
              checklist: @checklist,
              day: @day,
              item_index: new_index_position,
              total_items: active_tuples.length
            ))
          )
        ]
      end
    end
  end

  # PATCH /day_checklist_links/:id/reparent
  # Params: target_item_id (optional - nil means move to root)
  def reparent
    target_item_id = params[:target_item_id]

    # For now, just show a toast (full implementation would be similar to ItemsController#reparent)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(
          "body",
          "<script>window.toast && window.toast('Reparent not yet implemented for checklist links', { type: 'info' })</script>"
        )
      end
    end
  end

  # GET /day_checklist_links/:id/debug
  def debug
    # Debug info for development
    containing_descendant = @day.descendant

    respond_to do |format|
      format.turbo_stream do
        component_html = render_to_string(Views::DayChecklistLinks::DebugSheet.new(
          checklist: @checklist,
          day: @day,
          containing_descendant: containing_descendant
        ))
        render turbo_stream: turbo_stream.append("body", component_html)
      end
    end
  end

  private

  def set_checklist_and_day
    @checklist = current_user.checklists.find(params[:id])
    @day = current_user.days.find(params[:day_id])
  end
end
