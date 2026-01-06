# frozen_string_literal: true

class NotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_note, only: [ :show, :edit, :update, :destroy, :actions_sheet, :move, :reparent, :debug ]
  layout -> { ::Views::Layouts::AppLayout.new(pathname: request.path) }

  def index
    @search_query = params[:search_query]
    @page = params[:page] || 1

    notes_query = current_user.notes.ordered_by_date

    # Apply search if query present
    if @search_query.present?
      notes_query = notes_query.search(@search_query)
    end

    @notes = notes_query.page(@page).per(5)

    respond_to do |format|
      format.html do
        render ::Views::Notes::Index.new(
          notes: @notes,
          search_query: @search_query,
          page: @page
        )
      end
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "notes_filter_section",
          ::Views::Notes::List.new(
            notes: @notes,
            search_query: @search_query,
            page: @page
          )
        )
      end
    end
  end

  def show
    respond_to do |format|
      format.html { redirect_to notes_path }
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(
          "body",
          render_to_string(::Views::Notes::ShowDialog.new(note: @note))
        )
      end
    end
  end

  def new
    @note = current_user.notes.build

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(
          "body",
          render_to_string(::Views::Notes::FormDialog.new(note: @note))
        )
      end
    end
  end

  def create
    @note = current_user.notes.build(note_params)

    if @note.save
      respond_to do |format|
        format.html { redirect_to notes_path, notice: "Note created successfully" }
        format.turbo_stream do
          render turbo_stream: turbo_stream.prepend(
            "notes_list",
            render_to_string(::Views::Notes::NoteRow.new(note: @note, search_query: nil, page: 1))
          )
        end
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "note_form_errors",
            "<div class='text-sm text-destructive'>#{@note.errors.full_messages.join(', ')}</div>"
          ), status: :unprocessable_entity
        end
      end
    end
  end

  def edit
    @day = current_user.days.find(params[:day_id]) if params[:day_id].present?
    @list = current_user.lists.find(params[:list_id]) if params[:list_id].present?
    from_actions_sheet = params[:day_id].present? || params[:list_id].present?

    respond_to do |format|
      format.turbo_stream do
        if from_actions_sheet
          # Replace sheet content area (drawer navigation)
          render turbo_stream: turbo_stream.replace(
            "sheet_content_area",
            render_to_string(::Views::Notes::EditForm.new(note: @note, day: @day, list: @list))
          )
        else
          # Open new dialog (from notes index)
          render turbo_stream: turbo_stream.append(
            "body",
            render_to_string(::Views::Notes::FormDialog.new(note: @note))
          )
        end
      end
    end
  end

  def update
    @day = current_user.days.find(params[:day_id]) if params[:day_id].present?
    @list = current_user.lists.find(params[:list_id]) if params[:list_id].present?
    from_edit_form = params[:from_edit_form] == "true"

    if @note.update(note_params)
      respond_to do |format|
        format.html { redirect_to notes_path, notice: "Note updated successfully" }
        format.turbo_stream do
          streams = []

          # If from drawer, go back to actions sheet
          if from_edit_form && (@day || @list)
            # Get note index and total for move buttons
            descendant = @day&.descendant || @list&.descendant
            note_ids = descendant.extract_active_ids_by_type("Note")
            note_index = note_ids.index(@note.id)
            total_notes = note_ids.length

            streams << turbo_stream.replace(
              "sheet_content_area",
              render_to_string(::Views::Notes::ActionsSheetContent.new(
                note: @note,
                day: @day,
                list: @list,
                note_index: note_index,
                total_notes: total_notes
              ))
            )
          end

          # Try to update note in notes list (if present)
          streams << turbo_stream.replace(
            "note_row_#{@note.id}",
            render_to_string(::Views::Notes::NoteRow.new(note: @note, search_query: nil, page: 1))
          )

          # Try to update note in day view (if present)
          streams << turbo_stream.replace(
            "note_#{@note.id}",
            render_to_string(::Views::Notes::NoteItem.new(note: @note, day: @day, list: @list))
          )

          render turbo_stream: streams
        end
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "note_form_errors",
            "<div class='text-sm text-destructive'>#{@note.errors.full_messages.join(', ')}</div>"
          ), status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    @day = current_user.days.find(params[:day_id]) if params[:day_id].present?
    @list = current_user.lists.find(params[:list_id]) if params[:list_id].present?

    # Remove note from all descendants before destroying
    @note.parent_descendants.each do |descendant|
      descendant.remove_active_record("Note", @note.id)
      descendant.remove_inactive_record("Note", @note.id)
      descendant.save!
    end

    @note.destroy!

    respond_to do |format|
      format.html { redirect_to notes_path, notice: "Note deleted successfully" }
      format.turbo_stream do
        streams = []

        # If from day or list, refresh the tree
        if @day || @list
          # Reload to get fresh data
          if @day
            @day = current_user.days.includes(:descendant).find(@day.id)
            descendant = @day.descendant
          elsif @list
            @list = current_user.lists.includes(:descendant).find(@list.id)
            descendant = @list.descendant
          end

          # Rebuild the tree
          tree = ::ItemTree::Build.call(descendant, root_label: @day ? "day" : "list")

          # Render tree nodes
          rendered_items = tree.children.map do |node|
            render_to_string(::Views::Items::TreeNode.new(node: node, day: @day, list: @list))
          end.join

          streams << turbo_stream.update("items_list", rendered_items)
        end

        # Also try to remove from notes index if present
        streams << turbo_stream.remove("note_row_#{@note.id}")

        render turbo_stream: streams
      end
    end
  end

  def actions_sheet
    @day = current_user.days.find(params[:day_id]) if params[:day_id].present?
    @list = current_user.lists.find(params[:list_id]) if params[:list_id].present?

    # Get note index and total for move buttons
    if @day
      descendant = @day.descendant
      note_ids = descendant.extract_active_ids_by_type("Note")
      @note_index = note_ids.index(@note.id)
      @total_notes = note_ids.length
    elsif @list
      descendant = @list.descendant
      note_ids = descendant.extract_active_ids_by_type("Note")
      @note_index = note_ids.index(@note.id)
      @total_notes = note_ids.length
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(
          "body",
          render_to_string(::Views::Notes::ActionsSheet.new(
            note: @note,
            day: @day,
            list: @list,
            note_index: @note_index,
            total_notes: @total_notes
          ))
        )
      end
    end
  end

  def move
    @day = current_user.days.find(params[:day_id]) if params[:day_id].present?
    @list = current_user.lists.find(params[:list_id]) if params[:list_id].present?
    direction = params[:direction]

    descendant = @day&.descendant || @list&.descendant
    return head :unprocessable_entity unless descendant

    # Find note tuple in active_items
    note_tuple = { "Note" => @note.id }
    current_index = descendant.active_items.index(note_tuple)
    return head :unprocessable_entity unless current_index

    case direction
    when "up"
      return head :unprocessable_entity if current_index == 0
      descendant.active_items[current_index], descendant.active_items[current_index - 1] =
        descendant.active_items[current_index - 1], descendant.active_items[current_index]
    when "down"
      return head :unprocessable_entity if current_index >= descendant.active_items.length - 1
      descendant.active_items[current_index], descendant.active_items[current_index + 1] =
        descendant.active_items[current_index + 1], descendant.active_items[current_index]
    else
      return head :unprocessable_entity
    end

    descendant.save!

    respond_to do |format|
      format.turbo_stream do
        # Reload to get fresh data
        if @day
          @day = current_user.days.includes(:descendant).find(@day.id)
          descendant = @day.descendant
        elsif @list
          @list = current_user.lists.includes(:descendant).find(@list.id)
          descendant = @list.descendant
        end

        # Rebuild the tree to get fresh data
        tree = ::ItemTree::Build.call(descendant, root_label: @day ? "day" : "list")

        # Render tree nodes
        rendered_items = tree.children.map do |node|
          render_to_string(::Views::Items::TreeNode.new(node: node, day: @day, list: @list))
        end.join

        render turbo_stream: turbo_stream.update("items_list", rendered_items)
      end
    end
  end

  def reparent
    target_item_id = params[:target_item_id]

    # Get the day or list from params
    @day = current_user.days.find(params[:day_id]) if params[:day_id].present?
    @list = current_user.lists.find(params[:list_id]) if params[:list_id].present?

    # Determine target descendant
    target_descendant = if target_item_id.present?
      # Moving to a specific item's descendant
      target_item = current_user.items.find(target_item_id)
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

    # Use generic service to reparent
    ::ReparentService.new(
      record: @note,
      record_type: "Note",
      target_descendant: target_descendant
    ).call

    respond_to do |format|
      format.turbo_stream do
        if @day&.descendant
          # Reload to get fresh data
          @day = current_user.days.includes(:descendant).find(@day.id)
          descendant = @day.descendant

          # Build tree ONCE using ItemTree::Build
          tree = ::ItemTree::Build.call(descendant, root_label: "day")

          # Render tree nodes from the pre-built tree
          rendered_items = tree.children.map do |node|
            render_to_string(::Views::Items::TreeNode.new(node: node, day: @day))
          end.join

          render turbo_stream: turbo_stream.update("items_list", rendered_items)
        elsif @list&.descendant
          # Reload to get fresh data
          @list = current_user.lists.includes(:descendant).find(@list.id)
          descendant = @list.descendant

          # Build tree ONCE using ItemTree::Build
          tree = ::ItemTree::Build.call(descendant, root_label: "list")

          # Render tree nodes from the pre-built tree
          rendered_items = tree.children.map do |node|
            render_to_string(::Views::Items::TreeNode.new(node: node, list: @list))
          end.join

          render turbo_stream: turbo_stream.update("items_list", rendered_items)
        else
          head :ok
        end
      end
      format.html { redirect_back(fallback_location: root_path, notice: "Note moved successfully") }
    end
  end

  def debug
    parent_descendants = @note.parent_descendants.to_a

    respond_to do |format|
      format.turbo_stream do
        component_html = render_to_string(::Views::Notes::DebugSheet.new(
          note: @note,
          parent_descendants: parent_descendants
        ))
        render turbo_stream: turbo_stream.append("body", component_html)
      end
    end
  end

  private

  def set_note
    @note = current_user.notes.find(params[:id])
  end

  def note_params
    params.require(:note).permit(:content)
  end
end
