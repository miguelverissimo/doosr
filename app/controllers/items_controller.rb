# frozen_string_literal: true

class ItemsController < ApplicationController
  before_action :authenticate_user!, unless: :public_list_action?
  before_action :set_acting_user

  def create
    @item = @acting_user.items.build(item_params)

    # Note: Lists now use ReusableItemsController for item creation with duplicate detection
    # This controller is only for days and nested items

    if @item.save
      # Unfurl URL if title contains one
      ::Items::UrlUnfurlerService.call(@item)

      # Add item to parent item's descendant if parent_item_id provided
      if params[:parent_item_id].present?
        @parent_item = @acting_user.items.find(params[:parent_item_id])
        @day = @acting_user.days.find(params[:day_id]) if params[:day_id].present? && user_signed_in?

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
            # Reload parent with its descendant to get fresh data
            @parent_item = @acting_user.items.includes(:descendant).find(@parent_item.id)

            # Check if this is the first child
            is_first_child = @parent_item.descendant.active_items.count == 1

            # Calculate position of new item (extract IDs from tuples)
            active_item_ids = @parent_item.descendant.extract_active_item_ids
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
      # Add item to list's descendant if list_id provided
      elsif params[:list_id].present?
        @list ||= List.find(params[:list_id])

        # New item - add to list (duplicate check already done before save)
        @list.descendant.add_active_item(@item.id)
        @list.descendant.save!

        respond_to do |format|
          format.turbo_stream do
            # Reload to get fresh data
            @list.reload
            @list.descendant.reload

            # Build tree ONCE using ItemTree::Build
            tree = ItemTree::Build.call(@list.descendant, root_label: "list")

            # Render tree nodes from the pre-built tree
            rendered_items = tree.children.map do |node|
              render_to_string(Views::Items::TreeNode.new(node: node, context: @list, public_view: !user_signed_in?, is_editable: @list.visibility_editable?))
            end.join

            streams = [
              turbo_stream.update("items_list", rendered_items),
              turbo_stream.update("item_form_errors", "")
            ]

            # Broadcast to Action Cable for real-time updates
            broadcast_list_update(@list, streams)

            render turbo_stream: streams
          end
          format.html { redirect_back(fallback_location: root_path, notice: "Item created") }
        end
      # Add item to day's descendant active_items array if day_id provided
      elsif params[:day_id].present?
        @day = @acting_user.days.find(params[:day_id])
        @day.descendant.add_active_item(@item.id)
        @day.descendant.save!

        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.append(
                "items_list",
                ::Views::Items::CompletableItem.new(record: @item, day: @day, list: @list, is_public_list: false)
              ),
              turbo_stream.update("item_form_errors", "")
            ]
          end
          format.html { redirect_back(fallback_location: root_path, notice: "Item created") }
        end
      elsif params[:date].present?
        # Ensure day exists and is open (create new or reopen closed day)
        date = Date.parse(params[:date])
        existing_day = @acting_user.days.find_by(date: date)

        # Always use DayOpeningService to ensure day is open and has permanent sections
        if existing_day.nil? || existing_day.closed?
          result = Days::DayOpeningService.new(user: @acting_user, date: date).call
          unless result[:success]
            respond_to do |format|
              format.turbo_stream do
                render turbo_stream: turbo_stream.update(
                  "item_form_errors",
                  "<div class='text-destructive'>Failed to open day: #{result[:error]}</div>"
                )
              end
              format.html { redirect_back(fallback_location: root_path, alert: "Failed to open day") }
            end
            return
          end

          @day = result[:day]

          # CRITICAL: Track if we opened/reopened day (sections will be created)
          # - For NEW days: DayOpeningService already created sections
          # - For REOPENED days: We need to add sections manually
          day_was_opened_or_reopened = result[:created] || result[:reopened]

          if result[:reopened]
            # Only manually add sections for REOPENED days (new days already have them)
            Days::AddPermanentSectionsService.new(day: @day, user: @acting_user).call
          end
        else
          @day = existing_day
          day_was_opened_or_reopened = false
        end
        @day.descendant.add_active_item(@item.id)
        @day.descendant.save!

        respond_to do |format|
          format.turbo_stream do
            if day_was_opened_or_reopened
              # Day was created or reopened - refresh EVERYTHING
              @day.reload
              @day.descendant.reload

              # Update day header (shows state badge, etc.)
              rendered_header = render_to_string(
                Views::Days::Header.new(
                  date: @day.date,
                  day: @day,
                  latest_importable_day: nil
                ),
                layout: false
              )

              # Build the items tree (includes permanent sections + new item)
              tree = ItemTree::Build.call(@day.descendant, root_label: "day")
              rendered_items = tree.children.map do |node|
                render_to_string(Views::Items::TreeNode.new(node: node, day: @day))
              end.join

              render turbo_stream: [
                turbo_stream.update("day_header", rendered_header),
                turbo_stream.update("items_list", rendered_items),
                turbo_stream.update("item_form_errors", "")
              ]
            else
              # Day already existed and was open - just append the new item
              render turbo_stream: [
                turbo_stream.append(
                  "items_list",
                  ::Views::Items::CompletableItem.new(record: @item, day: @day, list: @list, is_public_list: false)
                ),
                turbo_stream.update("item_form_errors", "")
              ]
            end
          end
          format.html { redirect_back(fallback_location: root_path, notice: "Item created") }
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.append(
                "items_list",
                ::Views::Items::CompletableItem.new(record: @item, day: @day, list: @list, is_public_list: false)
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
            ::Views::Items::Errors.new(item: @item)
          )
        end
        format.html { redirect_back(fallback_location: root_path, alert: "Failed to create item") }
      end
    end
  end

  def update
    @item = @acting_user.items.find(params[:id])
    # @list may already be set by set_acting_user for public lists
    @list ||= @acting_user.lists.find(params[:list_id]) if params[:list_id].present?

    # Validate item type for lists - lists should ONLY have completable, reusable or section items
    if params[:list_id].present? && params.dig(:item, :item_type).present?
      new_item_type = params.dig(:item, :item_type)
      if new_item_type != "completable" && new_item_type != "reusable" && new_item_type != "section"
        @item.errors.add(:item_type, "Lists can only contain 'completable', 'reusable' or 'section' items")
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.update(
              "item_#{@item.id}_errors",
              ::Views::Items::Errors.new(item: @item)
            )
          end
          format.html { redirect_back(fallback_location: root_path, alert: "Invalid item type for list") }
        end
        return
      end
    end

    # Store old state and new state params before update
    old_state = @item.state
    new_state_param = params.dig(:item, :state)
    old_title = @item.title

    # Handle preview image removal if requested
    if params.dig(:item, :remove_preview_image) == "1"
      @item.preview_image.purge
    end

    # Handle extra_data updates manually to preserve other keys
    if params.dig(:item, :extra_data).present?
      updated_extra_data = @item.extra_data.merge(params[:item][:extra_data].to_unsafe_h)
      @item.extra_data = updated_extra_data
    end

    if @item.update(item_params.except(:remove_preview_image, :extra_data))
      # Unfurl URL if title changed and contains a URL
      if @item.title != old_title
        ::Items::UrlUnfurlerService.call(@item)
      end

      # State changes are now handled by the set_* methods on the Item model
      # No manual descendant management needed here

      respond_to do |format|
        format.turbo_stream do
          # If updating from edit form, return both the action sheet and the item update
          if params[:from_edit_form] == "true"
            @day = @acting_user.days.find(params[:day_id]) if params[:day_id].present? && user_signed_in?

            # Calculate position for move buttons
            item_index = nil
            total_items = nil
            tuple = { "Item" => @item.id }
            containing_descendant = Descendant.where("active_items @> ?", [ tuple ].to_json).first
            if containing_descendant
              active_item_ids = containing_descendant.extract_active_item_ids
              item_index = active_item_ids.index(@item.id)
              total_items = active_item_ids.length
            end

            is_public_list = params[:is_public_list] == "true"
            is_editable = @list&.visibility_editable? || false

            # Stream 1: Replace drawer content with action sheet content (not full drawer)
            streams = [
              turbo_stream.replace(
                "sheet_content_area",
                ::Views::Items::ActionsSheetContent.new(
                  item: @item,
                  day: @day,
                  list: @list,
                  item_index: item_index,
                  total_items: total_items,
                  is_public_list: is_public_list,
                  is_editable: is_editable
                )
              )
            ]

            # Stream 2: Update the item in the list/day view
            if @list
              # Reload to get fresh data
              @list.reload
              @list.descendant.reload

              # Build tree ONCE using ItemTree::Build
              tree = ItemTree::Build.call(@list.descendant, root_label: "list")

              # Render tree nodes from the pre-built tree
              rendered_items = tree.children.map do |node|
                render_to_string(Views::Items::TreeNode.new(node: node, context: @list, public_view: @is_public_list || false, is_editable: @list.visibility_editable?))
              end.join

              streams << turbo_stream.update("items_list", rendered_items)

              # Broadcast item update to list
              broadcast_list_update(@list, [ streams.last ])
            elsif @day
              # For day items, reload and re-render using proper component
              @item.reload
              streams << turbo_stream.replace(
                "item_#{@item.id}",
                ::Views::Items::CompletableItem.new(
                  record: @item,
                  day: @day,
                  list: nil,
                  is_public_list: false
                )
              )
            else
              # Fallback: reload and render
              @item.reload
              streams << turbo_stream.replace(
                "item_#{@item.id}",
                ::Views::Items::CompletableItem.new(
                  record: @item,
                  day: nil,
                  list: nil,
                  is_public_list: false
                )
              )
            end

            render turbo_stream: streams
          else
            # Replace the entire item+children wrapper for list items
            if @list
              # Reload to get fresh data
              @list.reload
              @list.descendant.reload

              # Build tree ONCE using ItemTree::Build
              tree = ItemTree::Build.call(@list.descendant, root_label: "list")

              # Render tree nodes from the pre-built tree
              rendered_items = tree.children.map do |node|
                render_to_string(Views::Items::TreeNode.new(node: node, context: @list, public_view: @is_public_list || false, is_editable: @list.visibility_editable?))
              end.join

              stream = turbo_stream.update("items_list", rendered_items)

              # Broadcast to list
              broadcast_list_update(@list, [ stream ])
            else
              stream = turbo_stream.replace(
                "item_#{@item.id}",
                ::Views::Items::CompletableItem.new(record: @item, day: @day, list: @list, is_public_list: @is_public_list || false)
              )
            end

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
            ::Views::Items::Errors.new(item: @item)
          )
        end
        format.html { redirect_back(fallback_location: root_path, alert: "Failed to update item") }
      end
    end
  end

  def destroy
    @item = @acting_user.items.find(params[:id])
    @day = find_day
    # @list may already be set by set_acting_user for public lists
    @list ||= @acting_user.lists.find(params[:list_id]) if params[:list_id].present?

    # Check if confirmation is needed (if item has nested items)
    if @item.has_nested_items? && params[:confirmed] != "true"
      # Return a response indicating confirmation is needed
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "sheet_content_area",
            ::Views::Items::DeleteConfirmation.new(
              item: @item,
              day: @day,
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
        streams = []

        # Remove the item from the UI
        if @list
          # Re-render the entire list
          @list.reload
          @list.descendant.reload

          # Build tree ONCE using ItemTree::Build
          tree = ItemTree::Build.call(@list.descendant, root_label: "list")

          # Render tree nodes from the pre-built tree
          rendered_items = tree.children.map do |node|
            render_to_string(Views::Items::TreeNode.new(node: node, context: @list))
          end.join

          streams << turbo_stream.update("items_list", rendered_items)
        elsif @day
          # Re-render the day's items
          @day.reload
          @day.descendant.reload

          # Build tree ONCE using ItemTree::Build
          tree = ItemTree::Build.call(@day.descendant, root_label: "day")

          # Render tree nodes from the pre-built tree
          rendered_items = tree.children.map do |node|
            render_to_string(Views::Items::TreeNode.new(node: node, day: @day))
          end.join

          streams << turbo_stream.update("items_list", rendered_items)
        else
          streams << turbo_stream.remove("item_with_children_#{@item.id}")
        end

        # Close the drawer
        streams << turbo_stream.remove("item_actions_sheet")

        # Broadcast to list if this is a list item
        broadcast_list_update(@list, streams) if @list

        render turbo_stream: streams
      end
      format.html do
        redirect_location = @list ? list_path(@list) : root_path
        redirect_to redirect_location, notice: "Item deleted"
      end
    end
  end

  def actions_sheet
    @item = @acting_user.items.find(params[:id])
    @day = @acting_user.days.find(params[:day_id]) if params[:day_id].present? && user_signed_in?
    @list = @acting_user.lists.find(params[:list_id]) if params[:list_id].present?

    # Detect if this is a public list view
    is_public_list = params[:is_public_list] == "true"
    is_editable = @list&.visibility_editable? || false

    # Calculate position for disabling move buttons
    # Find which descendant (Day, List, or Item) contains this item in its active_items
    item_index = nil
    total_items = nil

    # Find the containing descendant by checking which one has this item in active_items
    tuple = { "Item" => @item.id }
    containing_descendant = Descendant.where("active_items @> ?", [ tuple ].to_json).first

    if containing_descendant
      active_item_ids = containing_descendant.extract_active_item_ids
      item_index = active_item_ids.index(@item.id)
      total_items = active_item_ids.length
    end

    respond_to do |format|
      format.turbo_stream do
        # If coming from edit form, replace sheet content area only
        if params[:from_edit_form] == "true"
          render turbo_stream: turbo_stream.replace(
            "sheet_content_area",
            ::Views::Items::ActionsSheetContent.new(
              item: @item,
              day: @day,
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
            ::Views::Items::ActionsSheet.new(
              item: @item,
              day: @day,
              list: @list,
              item_index: item_index,
              total_items: total_items,
              is_public_list: is_public_list,
              is_editable: is_editable
            )
          )
          Rails.logger.debug "Component HTML length: #{component_html.length}"
          render turbo_stream: turbo_stream.append("body", component_html)
        end
      end
    end
  end

  def edit_form
    @item = @acting_user.items.find(params[:id])
    # @list may already be set by set_acting_user for public lists
    @list ||= @acting_user.lists.find(params[:list_id]) if params[:list_id].present?
    @day = @acting_user.days.find(params[:day_id]) if params[:day_id].present?

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "sheet_content_area",
          ::Views::Items::EditForm.new(item: @item, list: @list, day: @day)
        )
      end
    end
  end

  def defer_options
    @item = @acting_user.items.find(params[:id])
    @day = @acting_user.days.find(params[:day_id]) if params[:day_id].present? && user_signed_in?

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "sheet_content_area",
          ::Views::Items::DeferOptions.new(item: @item, day: @day)
        )
      end
    end
  end

  def recurrence_options
    @item = @acting_user.items.find(params[:id])
    @day = @acting_user.days.find(params[:day_id]) if params[:day_id].present? && user_signed_in?

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "sheet_content_area",
          ::Views::Items::RecurrenceOptions.new(item: @item, day: @day)
        )
      end
    end
  end

  def update_recurrence
    @item = @acting_user.items.find(params[:id])
    @day = @acting_user.days.find(params[:day_id]) if params[:day_id].present? && user_signed_in?

    # Parse the recurrence rule from params
    recurrence_rule = params[:recurrence_rule]

    # If the rule is "none" or empty, clear the recurrence
    if recurrence_rule.blank? || recurrence_rule == "none"
      @item.update!(recurrence_rule: nil)
    else
      # Parse JSON string if needed
      rule_hash = recurrence_rule.is_a?(String) ? JSON.parse(recurrence_rule) : recurrence_rule
      @item.update!(recurrence_rule: rule_hash.to_json)
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "sheet_content_area",
          ::Views::Items::ActionsSheet.new(item: @item, day: @day)
        )
      end
    end
  end

  def toggle_state
    @item = @acting_user.items.find(params[:id])
    new_state = params[:state]
    # @list may already be set by set_acting_user for public lists
    @list ||= @acting_user.lists.find(params[:list_id]) if params[:list_id].present?

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
        stream = turbo_stream.replace("item_#{@item.id}", ::Views::Items::CompletableItem.new(record: @item, day: find_day, list: @list, is_public_list: false))

        # Broadcast to list if this is a list item
        broadcast_list_update(@list, [ stream ]) if @list

        render turbo_stream: stream
      end
      format.html { redirect_back(fallback_location: root_path) }
    end
  end

  def move
    @item = @acting_user.items.find(params[:id])
    @day = @acting_user.days.find(params[:day_id]) if params[:day_id].present? && user_signed_in?
    # @list may already be set by set_acting_user for public lists
    @list ||= @acting_user.lists.find(params[:list_id]) if params[:list_id].present?
    direction = params[:direction]

    # Find which descendant contains this item
    tuple = { "Item" => @item.id }
    containing_descendant = Descendant.where("active_items @> ?", [ tuple ].to_json).first

    if containing_descendant
      active_items = containing_descendant.active_items
      # Find index of the tuple (not just the ID)
      current_index = active_items.index(tuple)

      if current_index
        new_index = direction == "up" ? current_index - 1 : current_index + 1

        # Only move if within bounds
        if new_index >= 0 && new_index < active_items.length
          # Swap the tuples (not just IDs)
          active_items[current_index], active_items[new_index] = active_items[new_index], active_items[current_index]
          containing_descendant.active_items = active_items
          containing_descendant.save!
        end
      end

      # Determine the type of descendant
      is_day_descendant = containing_descendant.descendable_type == "Day"
      is_list_descendant = containing_descendant.descendable_type == "List"
      parent_item = containing_descendant.descendable if containing_descendant.descendable_type == "Item"
    end

    respond_to do |format|
      format.turbo_stream do
        streams = []

        if is_list_descendant && @list&.descendant
          # Reload to get fresh data
          @list = @acting_user.lists.includes(:descendant).find(@list.id)

          # Build tree ONCE using ItemTree::Build
          tree = ItemTree::Build.call(@list.descendant, root_label: "list")

          # Render tree nodes from the pre-built tree
          rendered_items = tree.children.map do |node|
            render_to_string(Views::Items::TreeNode.new(node: node, context: @list))
          end.join

          streams << turbo_stream.update("items_list", rendered_items)

          # Update action sheet buttons if it's open
          active_item_ids = @list.descendant.active_items
          item_index = active_item_ids.index(@item.id)
          total_items = active_item_ids.length

          streams << turbo_stream.replace(
            "action_sheet_buttons_#{@item.id}",
            ::Views::Items::ActionsSheetButtonsListOwner.new(
              item: @item,
              list: @list,
              item_index: item_index,
              total_items: total_items
            )
          )

          # Broadcast to list subscribers
          broadcast_list_update(@list, streams)
        elsif is_day_descendant && @day&.descendant
          # Reload to get fresh data
          @day = @acting_user.days.includes(:descendant).find(@day.id)

          # Build tree ONCE using ItemTree::Build
          tree = ItemTree::Build.call(@day.descendant, root_label: "day")

          # Render tree nodes from the pre-built tree
          rendered_items = tree.children.map do |node|
            render_to_string(Views::Items::TreeNode.new(node: node, day: @day))
          end.join

          streams << turbo_stream.update("items_list", rendered_items)

          # Update action sheet buttons if it's open
          active_item_ids = @day.descendant.active_items
          item_index = active_item_ids.index(@item.id)
          total_items = active_item_ids.length

          streams << turbo_stream.replace(
            "action_sheet_buttons_#{@item.id}",
            ::Views::Items::ActionsSheetButtons.new(
              item: @item,
              day: @day,
              item_index: item_index,
              total_items: total_items
            )
          )
        elsif parent_item
          # Re-render the nested items in the drawer
          parent_item = @acting_user.items.includes(:descendant).find(parent_item.id)

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
            ::Views::Items::ActionsSheetButtons.new(
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
    @item = @acting_user.items.find(params[:id])
    target_item_id = params[:target_item_id]

    # Get the day or list from params
    @day = @acting_user.days.find(params[:day_id]) if params[:day_id].present? && user_signed_in?
    @list = @acting_user.lists.find(params[:list_id]) if params[:list_id].present?

    # Validate item type for lists - lists should ONLY have completable, reusable or section items
    if @list.present? && !@item.completable? && !@item.reusable? && !@item.section?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(
            "body",
            "<script>window.toast && window.toast('Cannot move this item type to a list. Lists can only contain completable, reusable or section items.', { type: 'danger' })</script>"
          )
        end
        format.html { redirect_back(fallback_location: root_path, alert: "Invalid item type for list") }
      end
      return
    end

    # Determine target descendant
    target_descendant = if target_item_id.present?
      # Moving to a specific item's descendant
      target_item = @acting_user.items.find(target_item_id)
      target_item.descendant || Descendant.create!(
        descendable: target_item,
        active_items: [],
        inactive_items: []
      )
    elsif @day&.descendant
      @day.descendant
    elsif @list&.descendant
      @list.descendant
    end

    # Use service to reparent
    Items::ReparentService.new(item: @item, target_descendant: target_descendant).call

    respond_to do |format|
      format.turbo_stream do
        if @day&.descendant
          # Reload to get fresh data
          @day.reload
          @day.descendant.reload

          # Build tree ONCE using ItemTree::Build
          tree = ItemTree::Build.call(@day.descendant, root_label: "day")

          # Render tree nodes from the pre-built tree
          rendered_items = tree.children.map do |node|
            render_to_string(Views::Items::TreeNode.new(node: node, day: @day))
          end.join

          render turbo_stream: turbo_stream.update("items_list", rendered_items)
        elsif @list&.descendant
          # Reload to get fresh data
          @list.reload
          @list.descendant.reload

          # Build tree ONCE using ItemTree::Build
          tree = ItemTree::Build.call(@list.descendant, root_label: "list")

          # Render tree nodes from the pre-built tree
          rendered_items = tree.children.map do |node|
            render_to_string(Views::Items::TreeNode.new(node: node, context: @list))
          end.join

          stream = turbo_stream.update("items_list", rendered_items)

          # Broadcast to list subscribers
          broadcast_list_update(@list, [ stream ])

          render turbo_stream: stream
        else
          head :ok
        end
      end
      format.html { redirect_back(fallback_location: root_path, notice: "Item moved successfully") }
    end
  end

  def defer
    @item = @acting_user.items.find(params[:id])
    target_date_param = params[:target_date]

    # Parse target date
    target_date = case target_date_param
    when "tomorrow"
      Item.get_tomorrow_date
    when "next_monday"
      Item.get_next_monday_date
    when "next_month"
      Item.get_next_month_first_date
    else
      Date.parse(target_date_param)
    end

    # Check if confirmation is needed (if item has nested items)
    if @item.has_nested_items? && params[:confirmed] != "true"
      @day = find_day
      # Return a response indicating confirmation is needed
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "sheet_content_area",
            ::Views::Items::DeferConfirmation.new(
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
      user: @acting_user
    )

    result = service.call

    if result[:success]
      nested_count = result[:nested_items_count]
      deferred_count = nested_count + 1 # +1 for the source item itself

      # Find the day to refresh the UI
      @day = find_day

      respond_to do |format|
        format.turbo_stream do
          if @day&.descendant
            # Reload to get fresh data
            @day.reload
            @day.descendant.reload

            # Build tree ONCE using ItemTree::Build
            tree = ItemTree::Build.call(@day.descendant, root_label: "day")

            # Render tree nodes from the pre-built tree
            rendered_items = tree.children.map do |node|
              render_to_string(Views::Items::TreeNode.new(node: node, day: @day))
            end.join

            # Reload the item to get fresh state
            @item.reload

            # Get active item IDs for positioning
            active_item_ids = @day.descendant.extract_active_item_ids

            # Calculate position for the actions sheet
            item_index = active_item_ids.index(@item.id)
            total_items = active_item_ids.length

            # Show toast and reload the actions sheet
            toast_message = "#{deferred_count} item#{deferred_count > 1 ? 's' : ''} deferred to #{target_date.strftime('%b %-d, %Y')}"

            render turbo_stream: [
              turbo_stream.update("items_list", rendered_items),
              turbo_stream.replace(
                "sheet_content_area",
                ::Views::Items::ActionsSheetContent.new(
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
    else
      # Handle error case
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append("body", "<script>window.toast && window.toast(#{result[:error].to_json}, { type: 'error' })</script>")
        end
        format.html { redirect_back(fallback_location: root_path, alert: result[:error]) }
      end
    end
  end

  def undefer
    @item = @acting_user.items.find(params[:id])

    # Undefer the item using the service
    service = ::Items::UndeferService.new(
      source_item: @item,
      user: @acting_user
    )

    result = service.call

    if result[:success]
      # Find the day to refresh the UI
      @day = find_day

      respond_to do |format|
        format.turbo_stream do
          if @day&.descendant
            # Reload to get fresh data
            @day.reload
            @day.descendant.reload

            # Build tree ONCE using ItemTree::Build
            tree = ItemTree::Build.call(@day.descendant, root_label: "day")

            # Render tree nodes from the pre-built tree
            rendered_items = tree.children.map do |node|
              render_to_string(Views::Items::TreeNode.new(node: node, day: @day))
            end.join

            # Reload the item to get fresh state
            @item.reload

            # Get active item IDs for positioning
            active_item_ids = @day.descendant.extract_active_item_ids

            # Calculate position for the actions sheet
            item_index = active_item_ids.index(@item.id)
            total_items = active_item_ids.length

            # Show toast and update the UI
            toast_message = "Item restored to todo"

            render turbo_stream: [
              turbo_stream.update("items_list", rendered_items),
              turbo_stream.replace(
                "action_sheet_buttons_#{@item.id}",
                ::Views::Items::ActionsSheetButtons.new(
                  item: @item,
                  day: @day,
                  item_index: item_index,
                  total_items: total_items
                )
              ),
              turbo_stream.append("body", "<script>window.toast && window.toast(#{toast_message.to_json}, { type: 'success' })</script>")
            ]
          else
            flash[:alert] = "Failed to undefer item"
            head :ok
          end
        end
        format.html { redirect_back(fallback_location: root_path, notice: "Item restored to todo") }
      end
    else
      # Handle error case
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append("body", "<script>window.toast && window.toast(#{result[:error].to_json}, { type: 'error' })</script>")
        end
        format.html { redirect_back(fallback_location: root_path, alert: result[:error]) }
      end
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
    params[:list_id].present? && !user_signed_in?
  end

  def set_acting_user
    if user_signed_in?
      @acting_user = current_user
      @is_public_list = false
    elsif params[:list_id].present?
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

  def item_params
    params.require(:item).permit(:title, :item_type, :state, :notification_time, :remove_preview_image, extra_data: [:unfurled_url, :unfurled_description])
  end

  def find_day
    return nil unless params[:day_id].present? && user_signed_in?
    @acting_user.days.find(params[:day_id])
  end

  def broadcast_list_update(list, streams)
    return unless list

    # Streams are already rendered HTML strings, just join them
    html = streams.map(&:to_s).join

    Rails.logger.debug "=== Broadcasting to list_channel:#{list.id} ==="
    Rails.logger.debug "HTML length: #{html.length}"
    Rails.logger.debug "First 200 chars: #{html[0..200]}"

    # Broadcast to all subscribers of this list
    ActionCable.server.broadcast("list_channel:#{list.id}", { html: html })

    Rails.logger.debug "=== Broadcast complete ==="
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

  # Recursively delete an item and all its descendants
  def delete_item_with_descendants(item)
    return unless item

    # If item has descendants, delete them first
    if item.descendant
      descendant = item.descendant
      all_child_ids = descendant.active_items + descendant.inactive_items
      child_items = Item.where(id: all_child_ids).includes(:descendant)

      # Recursively delete each child
      child_items.each do |child_item|
        delete_item_with_descendants(child_item)
      end

      # Delete the descendant record
      descendant.destroy!
    end

    # Find and remove item from any parent descendant
    parent_descendant = Descendant.containing_item(item.id)

    if parent_descendant
      parent_descendant.remove_active_item(item.id)
      parent_descendant.remove_inactive_item(item.id)
      parent_descendant.save!
    end

    # Finally, delete the item itself
    item.destroy!
  end
end
