# frozen_string_literal: true

class DayJournalLinksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_journal_and_day, only: [ :destroy, :actions_sheet, :move, :debug ]

  # POST /day_journal_links
  # Params: day_id
  def create
    @day = current_user.days.find(params[:day_id])

    # Check if journal already linked
    if @day.descendant.extract_active_ids_by_type("Journal").any?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(
            "body",
            "<script>window.toast && window.toast('Journal already linked to this day', { type: 'warning' })</script>"
          )
        end
      end
      return
    end

    # Open or create journal for this day's date
    result = ::Journals::OpenOrCreateService.call(user: current_user, date: @day.date)
    @journal = result[:journal]

    # Add journal to day's descendant
    @day.descendant.add_active_record("Journal", @journal.id)
    @day.descendant.save!

    respond_to do |format|
      format.turbo_stream do
        # Rebuild day's item tree
        tree = ::ItemTree::Build.call(@day.descendant, root_label: "day")
        rendered_items = tree.children.map do |node|
          render_to_string(::Views::Items::TreeNode.new(node: node, day: @day))
        end.join

        render turbo_stream: [
          turbo_stream.update("items_list", rendered_items),
          turbo_stream.append("body", "<script>window.toast && window.toast('Journal link added', { type: 'success' })</script>")
        ]
      end
    end
  end

  # DELETE /day_journal_links/:id
  # :id is the journal_id
  # Removes journal from day's descendant ONLY - does NOT delete journal record
  def destroy
    # Remove journal from day's descendant
    @day.descendant.remove_active_record("Journal", @journal.id)
    @day.descendant.save!

    respond_to do |format|
      format.turbo_stream do
        # Rebuild and close drawer
        tree = ::ItemTree::Build.call(@day.descendant, root_label: "day")
        rendered_items = tree.children.map do |node|
          render_to_string(::Views::Items::TreeNode.new(node: node, day: @day))
        end.join

        render turbo_stream: [
          turbo_stream.update("items_list", rendered_items),
          turbo_stream.remove("actions_sheet"),
          turbo_stream.append("body", "<script>window.toast && window.toast('Journal link removed', { type: 'success' })</script>")
        ]
      end
    end
  end

  # GET /day_journal_links/:id/actions
  def actions_sheet
    # Calculate position for move buttons
    tuple = { "Journal" => @journal.id }
    containing_descendant = @day.descendant

    if containing_descendant
      active_tuples = containing_descendant.active_items
      item_index = active_tuples.index(tuple)
      total_items = active_tuples.length
    end

    respond_to do |format|
      format.turbo_stream do
        component_html = render_to_string(::Views::DayJournalLinks::ActionsSheet.new(
          journal: @journal,
          day: @day,
          item_index: item_index,
          total_items: total_items
        ))
        render turbo_stream: turbo_stream.append("body", component_html)
      end
    end
  end

  # PATCH /day_journal_links/:id/move
  # Params: direction (up/down)
  def move
    direction = params[:direction]
    tuple = { "Journal" => @journal.id }
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
        tree = ::ItemTree::Build.call(@day.descendant, root_label: "day")
        rendered_items = tree.children.map do |node|
          render_to_string(::Views::Items::TreeNode.new(node: node, day: @day))
        end.join

        # Also update action sheet buttons with new position
        new_index_position = descendant.active_items.index(tuple)

        render turbo_stream: [
          turbo_stream.update("items_list", rendered_items),
          turbo_stream.replace(
            "action_sheet_buttons_journal_#{@journal.id}",
            render_to_string(::Views::DayJournalLinks::ActionButtons.new(
              journal: @journal,
              day: @day,
              item_index: new_index_position,
              total_items: active_tuples.length
            ))
          )
        ]
      end
    end
  end

  # GET /day_journal_links/:id/debug
  def debug
    # Debug info for development
    containing_descendant = @day.descendant

    respond_to do |format|
      format.turbo_stream do
        component_html = render_to_string(::Views::DayJournalLinks::DebugSheet.new(
          journal: @journal,
          day: @day,
          containing_descendant: containing_descendant
        ))
        render turbo_stream: turbo_stream.append("body", component_html)
      end
    end
  end

  private

  def set_journal_and_day
    @journal = current_user.journals.find(params[:id])
    @day = current_user.days.find(params[:day_id])
  end
end
