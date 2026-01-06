# frozen_string_literal: true

class ItemNotesController < ApplicationController
  before_action :authenticate_user!

  def create
    @item = current_user.items.find(params[:item_id])
    @note = current_user.notes.build(note_params)

    if @note.save
      # Add note to item's descendant (create if doesn't exist)
      item_descendant = @item.descendant || ::Descendant.create!(
        descendable: @item,
        active_items: [],
        inactive_items: []
      )

      item_descendant.add_active_record("Note", @note.id)
      item_descendant.save!

      respond_to do |format|
        format.html { redirect_back(fallback_location: root_path, notice: "Note added to item") }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove("note_dialog"),
            turbo_stream.replace(
              "sheet_content_area",
              render_to_string(::Views::Items::ActionsSheetContent.new(
                item: @item,
                day: @day,
                list: nil
              ))
            )
          ]
        end
      end
    else
      respond_to do |format|
        format.html { redirect_back(fallback_location: root_path, alert: @note.errors.full_messages.join(", ")) }
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
