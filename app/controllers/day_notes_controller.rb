# frozen_string_literal: true

class DayNotesController < ApplicationController
  before_action :authenticate_user!

  def new
    @day = current_user.days.find(params[:day_id])
    @note = current_user.notes.build

    respond_to do |format|
      format.html { redirect_to day_path(@day.date) }
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(
          "body",
          render_to_string(::Views::Notes::FormDialog.new(note: @note, day: @day))
        )
      end
    end
  end

  def create
    @day = current_user.days.find(params[:day_id])
    @note = current_user.notes.build(note_params)

    if @note.save
      # Add note to day's descendant
      @day.descendant.add_active_record("Note", @note.id)
      @day.descendant.save!

      respond_to do |format|
        format.html { redirect_to day_path(@day.date), notice: "Note added to day" }
        format.turbo_stream do
          # Reload to get fresh data
          @day.reload
          @day.descendant.reload

          # Rebuild the tree to include the new note
          tree = ::ItemTree::Build.call(@day.descendant, root_label: "day")

          # Find the note node in the tree
          note_node = tree.children.find { |node| node.note&.id == @note.id }

          # Add the note to the list if we found it
          if note_node
            render turbo_stream: turbo_stream.append(
              "items_list",
              render_to_string(::Views::Items::TreeNode.new(node: note_node, day: @day))
            )
          else
            head :ok
          end
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to day_path(@day.date), alert: @note.errors.full_messages.join(", ") }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "note_form_errors",
            "<div class='text-sm text-destructive'>#{@note.errors.full_messages.join(', ')}</div>"
          ), status: :unprocessable_entity
        end
      end
    end
  end

  private

  def note_params
    params.require(:note).permit(:content)
  end
end
