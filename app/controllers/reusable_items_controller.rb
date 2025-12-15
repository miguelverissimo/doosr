# frozen_string_literal: true

# ReusableItemsController handles creation of completable/reusable items in lists
# This controller is ONLY used for lists and handles duplicate detection
class ReusableItemsController < ApplicationController
  before_action :authenticate_user!, unless: :public_list_action?
  before_action :set_acting_user
  before_action :set_list

  def create
    @item = @acting_user.items.build(item_params)

    # Validate item type - ONLY reusable or section
    unless @item.reusable? || @item.section?
      @item.errors.add(:item_type, "Lists can only contain 'reusable' or 'section' items")
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "item_form_errors",
            Views::Items::Errors.new(item: @item)
          )
        end
        format.html { redirect_back(fallback_location: root_path, alert: "Invalid item type for list") }
      end
      return
    end

    # Check for duplicates ONLY for reusable items (not sections)
    if @item.reusable?
      existing_item = find_duplicate_item(@item.title)
      Rails.logger.debug "=== DUPLICATE DETECTION ==="
      Rails.logger.debug "Looking for: #{@item.title.downcase}"
      Rails.logger.debug "Existing item: #{existing_item&.id}:#{existing_item&.title}"
      Rails.logger.debug "=== END DUPLICATE DETECTION ==="

      if existing_item
        handle_existing_item(existing_item)
        return
      end
    end

    # No duplicate found - create new item
    if @item.save
      @list.descendant.add_active_item(@item.id)
      @list.descendant.save!

      respond_to do |format|
        format.turbo_stream do
          render_list_update
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

  def actions_sheet
    @item = @acting_user.items.find(params[:id])
    @list = @acting_user.lists.find(params[:list_id]) if params[:list_id].present?

    # Detect if this is a public list view
    is_public_list = params[:is_public_list] == "true"
    is_editable = @list&.visibility_editable? || false

    # Calculate position for disabling move buttons
    item_index = nil
    total_items = nil

    # Find the containing descendant
    containing_descendant = Descendant.containing_item(@item.id)

    if containing_descendant
      active_items = containing_descendant.active_items
      item_index = active_items.index(@item.id)
      total_items = active_items.length
    end

    respond_to do |format|
      format.turbo_stream do
        # If coming from edit form, replace sheet content area only
        if params[:from_edit_form] == "true"
          render turbo_stream: turbo_stream.replace(
            "sheet_content_area",
            Views::Items::ActionsSheetContent.new(
              item: @item,
              day: nil,
              list: @list,
              item_index: item_index,
              total_items: total_items,
              is_public_list: is_public_list,
              is_editable: is_editable
            )
          )
        else
          # Coming from clicking item - append to body to open drawer
          component_html = render_to_string(
            Views::Items::ActionsSheet.new(
              item: @item,
              day: nil,
              list: @list,
              item_index: item_index,
              total_items: total_items,
              is_public_list: is_public_list,
              is_editable: is_editable
            )
          )
          render turbo_stream: turbo_stream.append("body", component_html)
        end
      end
    end
  end

  def edit_form
    @item = @acting_user.items.find(params[:id])
    @list ||= @acting_user.lists.find(params[:list_id]) if params[:list_id].present?

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "sheet_content_area",
          Views::Items::EditForm.new(item: @item, list: @list, day: nil)
        )
      end
    end
  end

  def toggle_state
    @item = @acting_user.items.find(params[:id])
    new_state = params[:state]
    @list ||= @acting_user.lists.find(params[:list_id]) if params[:list_id].present?

    Rails.logger.debug "=== TOGGLE STATE ==="
    Rails.logger.debug "Item: #{@item.id}:#{@item.title}"
    Rails.logger.debug "New state: #{new_state}"
    Rails.logger.debug "=== END TOGGLE STATE ==="

    # Use centralized state change methods - they handle descendant management
    case new_state
    when "done"
      @item.set_done!
    when "dropped"
      @item.set_dropped!
    when "todo"
      @item.set_todo!
    end

    respond_to do |format|
      format.turbo_stream do
        streams = []

        # Stream 1: Update the item in the list view
        streams << turbo_stream.replace("item_#{@item.id}", Views::Items::Item.new(item: @item, day: nil, list: @list))

        # Stream 2: Update action sheet buttons if drawer is open
        # Recalculate position for move buttons
        containing_descendant = Descendant.containing_item(@item.id)
        if containing_descendant
          active_items = containing_descendant.active_items
          item_index = active_items.index(@item.id)
          total_items = active_items.length

          # Determine if this is a public list view
          is_public_list = params[:is_public_list] == "true"
          is_editable = @list&.visibility_editable? || false

          # Choose the appropriate buttons component based on context
          buttons_component = if is_public_list
            Views::Items::ActionsSheetButtonsListPublic.new(
              item: @item,
              list: @list,
              item_index: item_index,
              total_items: total_items,
              is_editable: is_editable
            )
          else
            Views::Items::ActionsSheetButtonsListOwner.new(
              item: @item,
              list: @list,
              item_index: item_index,
              total_items: total_items
            )
          end

          streams << turbo_stream.replace("action_sheet_buttons_#{@item.id}", buttons_component)
        end

        # Broadcast to list
        broadcast_list_update(@list, streams) if @list

        render turbo_stream: streams
      end
      format.html { redirect_back(fallback_location: root_path) }
    end
  end

  def move
    @item = @acting_user.items.find(params[:id])
    @list ||= @acting_user.lists.find(params[:list_id]) if params[:list_id].present?
    direction = params[:direction]

    # Find which descendant contains this item
    containing_descendant = Descendant.containing_item(@item.id)

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
    end

    respond_to do |format|
      format.turbo_stream do
        # Reload to get fresh data
        @list.reload
        @list.descendant.reload

        # Build tree
        tree = ItemTree::Build.call(@list.descendant, root_label: "list")

        # Render tree nodes
        rendered_items = tree.children.map do |node|
          render_to_string(Views::Items::TreeNode.new(node: node, context: @list, public_view: !user_signed_in?, is_editable: @list.visibility_editable?))
        end.join

        streams = [turbo_stream.update("items_list", rendered_items)]

        # Update action sheet buttons if it's open
        active_item_ids = @list.descendant.active_items
        item_index = active_item_ids.index(@item.id)
        total_items = active_item_ids.length

        streams << turbo_stream.replace(
          "action_sheet_buttons_#{@item.id}",
          Views::Items::ActionsSheetButtonsListOwner.new(
            item: @item,
            list: @list,
            item_index: item_index,
            total_items: total_items
          )
        )

        # Broadcast to list subscribers
        broadcast_list_update(@list, streams)

        render turbo_stream: streams
      end
      format.html { redirect_back(fallback_location: root_path) }
    end
  end

  def update
    @item = @acting_user.items.find(params[:id])
    @list ||= @acting_user.lists.find(params[:list_id]) if params[:list_id].present?

    # Validate item type - ONLY reusable or section
    if params.dig(:item, :item_type).present?
      new_item_type = params.dig(:item, :item_type)
      unless new_item_type == "reusable" || new_item_type == "section"
        @item.errors.add(:item_type, "Lists can only contain 'reusable' or 'section' items")
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.update(
              "item_#{@item.id}_errors",
              Views::Items::Errors.new(item: @item)
            )
          end
          format.html { redirect_back(fallback_location: root_path, alert: "Invalid item type for list") }
        end
        return
      end
    end

    if @item.update(item_params)
      respond_to do |format|
        format.turbo_stream do
          # If updating from edit form, return both the action sheet and the item update
          if params[:from_edit_form] == "true"
            # Calculate position for move buttons
            item_index = nil
            total_items = nil
            containing_descendant = Descendant.containing_item(@item.id)
            if containing_descendant
              active_items = containing_descendant.active_items
              item_index = active_items.index(@item.id)
              total_items = active_items.length
            end

            is_public_list = params[:is_public_list] == "true"
            is_editable = @list&.visibility_editable? || false

            # Stream 1: Replace drawer content with action sheet content
            streams = [
              turbo_stream.replace(
                "sheet_content_area",
                Views::Items::ActionsSheetContent.new(
                  item: @item,
                  day: nil,
                  list: @list,
                  item_index: item_index,
                  total_items: total_items,
                  is_public_list: is_public_list,
                  is_editable: is_editable
                )
              )
            ]

            # Stream 2: Update the item in the list view
            @list.reload
            @list.descendant.reload

            tree = ItemTree::Build.call(@list.descendant, root_label: "list")

            rendered_items = tree.children.map do |node|
              render_to_string(Views::Items::TreeNode.new(node: node, context: @list, public_view: @is_public_list || false, is_editable: @list.visibility_editable?))
            end.join

            streams << turbo_stream.update("items_list", rendered_items)

            # Broadcast item update to list
            broadcast_list_update(@list, [streams.last])

            render turbo_stream: streams
          else
            # Reload to get fresh data
            @list.reload
            @list.descendant.reload

            tree = ItemTree::Build.call(@list.descendant, root_label: "list")

            rendered_items = tree.children.map do |node|
              render_to_string(Views::Items::TreeNode.new(node: node, context: @list, public_view: @is_public_list || false, is_editable: @list.visibility_editable?))
            end.join

            stream = turbo_stream.update("items_list", rendered_items)

            # Broadcast to list
            broadcast_list_update(@list, [stream])

            render turbo_stream: stream
          end
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
    @item = @acting_user.items.find(params[:id])
    @list ||= @acting_user.lists.find(params[:list_id]) if params[:list_id].present?

    # Check if confirmation is needed (if item has nested items)
    if @item.has_nested_items? && params[:confirmed] != 'true'
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "sheet_content_area",
            Views::Items::DeleteConfirmation.new(
              item: @item,
              day: nil,
              list: @list
            )
          )
        end
        format.html { redirect_back(fallback_location: root_path, alert: "Confirmation required") }
      end
      return
    end

    # Delete the item and all its descendants recursively
    delete_item_with_descendants(@item)

    respond_to do |format|
      format.turbo_stream do
        # Re-render the entire list
        @list.reload
        @list.descendant.reload

        tree = ItemTree::Build.call(@list.descendant, root_label: "list")

        rendered_items = tree.children.map do |node|
          render_to_string(Views::Items::TreeNode.new(node: node, context: @list, public_view: !user_signed_in?, is_editable: @list.visibility_editable?))
        end.join

        streams = [
          turbo_stream.update("items_list", rendered_items),
          turbo_stream.remove("item_actions_sheet")
        ]

        # Broadcast to list
        broadcast_list_update(@list, streams)

        render turbo_stream: streams
      end
      format.html { redirect_to list_path(@list), notice: "Item deleted" }
    end
  end

  def reparent
    @item = @acting_user.items.find(params[:id])
    target_item_id = params[:target_item_id]
    @list = @acting_user.lists.find(params[:list_id]) if params[:list_id].present?

    # Validate item type - lists should ONLY have reusable or section items
    if @list.present? && !@item.reusable? && !@item.section?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(
            "body",
            "<script>window.toast && window.toast('Cannot move this item type to a list. Lists can only contain reusable or section items.', { type: 'danger' })</script>"
          )
        end
        format.html { redirect_back(fallback_location: root_path, alert: "Invalid item type for list") }
      end
      return
    end

    # Determine target descendant
    target_descendant = if target_item_id.present?
      target_item = @acting_user.items.find(target_item_id)
      target_item.descendant || Descendant.create!(
        descendable: target_item,
        active_items: [],
        inactive_items: []
      )
    elsif @list&.descendant
      @list.descendant
    end

    # Use service to reparent
    Items::ReparentService.new(item: @item, target_descendant: target_descendant).call

    respond_to do |format|
      format.turbo_stream do
        # Reload to get fresh data
        @list.reload
        @list.descendant.reload

        tree = ItemTree::Build.call(@list.descendant, root_label: "list")

        rendered_items = tree.children.map do |node|
          render_to_string(Views::Items::TreeNode.new(node: node, context: @list, public_view: !user_signed_in?, is_editable: @list.visibility_editable?))
        end.join

        stream = turbo_stream.update("items_list", rendered_items)

        # Broadcast to list subscribers
        broadcast_list_update(@list, [stream])

        render turbo_stream: stream
      end
      format.html { redirect_back(fallback_location: root_path, notice: "Item moved successfully") }
    end
  end

  def debug
    @item = @acting_user.items.find(params[:id])

    # Find which descendant contains this item
    @containing_descendant = Descendant.containing_item(@item.id)
    @owner = @containing_descendant&.descendable

    respond_to do |format|
      format.turbo_stream do
        component_html = render_to_string(Views::Items::DebugSheet.new(item: @item, containing_descendant: @containing_descendant, owner: @owner))
        render turbo_stream: turbo_stream.append("body", component_html)
      end
    end
  end

  private

  def public_list_action?
    !user_signed_in?
  end

  def set_acting_user
    if user_signed_in?
      @acting_user = current_user
      @is_public_list = false
    else
      # Public list action - use list owner as acting user
      @list = List.find_by(id: params[:list_id])
      if @list&.list_type_public_list? && @list&.visibility_editable?
        @acting_user = @list.user
        @is_public_list = true
      else
        redirect_to root_path, alert: "List not found or not accessible"
      end
    end
  end

  def set_list
    @list ||= List.find(params[:list_id])
  end

  def item_params
    params.require(:item).permit(:title, :item_type, :state)
  end

  def find_duplicate_item(title)
    # Find all item IDs ONLY within THIS specific list (including nested items)
    # This is scoped to @list - items in other lists are NOT checked
    all_item_ids = find_all_list_item_ids_recursively(@list)
    all_items = @acting_user.items.where(id: all_item_ids)

    # Look for duplicate (case insensitive, ONLY reusable items in THIS list)
    all_items.find do |item|
      item.title.downcase == title.downcase && item.reusable?
    end
  end

  def handle_existing_item(existing_item)
    # Check if item is active or inactive
    containing_descendant = Descendant.containing_item(existing_item.id)
    Rails.logger.debug "=== HANDLING EXISTING ITEM ==="
    Rails.logger.debug "Item: #{existing_item.id}:#{existing_item.title}"
    Rails.logger.debug "Containing descendant: #{containing_descendant.id}"
    Rails.logger.debug "Active items: #{containing_descendant.active_items.inspect}"
    Rails.logger.debug "Inactive items: #{containing_descendant.inactive_items.inspect}"
    Rails.logger.debug "=== END HANDLING EXISTING ITEM ==="

    if containing_descendant && containing_descendant.active_items.include?(existing_item.id)
      Rails.logger.debug "=== ALREADY ACTIVE ==="
      # Already active - do nothing
      @item = existing_item
      toast_message = "#{existing_item.title} already in list"
    else
      Rails.logger.debug "=== INACTIVE ==="
      # Inactive - mark as todo (moves to active items)
      existing_item.set_todo!
      @item = existing_item
      toast_message = "#{existing_item.title} marked as todo"
    end

    respond_to do |format|
      format.turbo_stream do
        render_list_update(toast_message)
      end
      format.html { redirect_back(fallback_location: root_path, notice: toast_message) }
    end
  end

  def render_list_update(toast_message = nil)
    # Reload to get fresh data
    @list.reload
    @list.descendant.reload

    # Build tree
    tree = ItemTree::Build.call(@list.descendant, root_label: "list")

    # Render tree nodes
    rendered_items = tree.children.map do |node|
      render_to_string(Views::Items::TreeNode.new(node: node, context: @list, public_view: !user_signed_in?, is_editable: @list.visibility_editable?))
    end.join

    streams = [
      turbo_stream.update("items_list", rendered_items),
      turbo_stream.update("item_form_errors", "")
    ]

    # Add toast if present
    if toast_message
      streams << turbo_stream.append("body", "<script>window.toast && window.toast(#{toast_message.to_json}, { type: 'info' })</script>")
    end

    # Broadcast to Action Cable
    broadcast_list_update(@list, streams)

    render turbo_stream: streams
  end

  def broadcast_list_update(list, streams)
    return unless list

    html = streams.map(&:to_s).join
    ActionCable.server.broadcast("list_channel:#{list.id}", { html: html })
  end

  def delete_item_with_descendants(item)
    return unless item

    # If item has a descendant, recursively delete all nested items
    if item.descendant
      all_item_ids = item.descendant.active_items + item.descendant.inactive_items
      nested_items = Item.where(id: all_item_ids)

      nested_items.each do |nested_item|
        delete_item_with_descendants(nested_item)
      end

      # Delete the descendant
      item.descendant.destroy
    end

    # Delete the item itself
    item.destroy
  end

  # Recursively find all item IDs in a list, including nested items
  def find_all_list_item_ids_recursively(list)
    return [] unless list.descendant

    item_ids = []
    descendant = list.descendant

    # Get direct items
    direct_item_ids = descendant.active_items + descendant.inactive_items
    item_ids.concat(direct_item_ids)

    # Get all items to check for nested descendants
    items = Item.where(id: direct_item_ids).includes(:descendant)

    # Recursively get nested items
    items.each do |item|
      if item.descendant
        nested_ids = find_all_item_ids_recursively_from_item(item)
        item_ids.concat(nested_ids)
      end
    end

    item_ids.uniq
  end

  # Helper to recursively find item IDs from an item's descendant
  def find_all_item_ids_recursively_from_item(item)
    return [] unless item.descendant

    item_ids = []
    descendant = item.descendant

    # Get direct nested items
    nested_item_ids = descendant.active_items + descendant.inactive_items
    item_ids.concat(nested_item_ids)

    # Get all nested items to check for further nesting
    nested_items = Item.where(id: nested_item_ids).includes(:descendant)

    # Recursively get nested items
    nested_items.each do |nested_item|
      if nested_item.descendant
        deeper_ids = find_all_item_ids_recursively_from_item(nested_item)
        item_ids.concat(deeper_ids)
      end
    end

    item_ids.uniq
  end

end
