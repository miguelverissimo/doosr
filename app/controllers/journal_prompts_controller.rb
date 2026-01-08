# frozen_string_literal: true

class JournalPromptsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_prompt, only: [ :destroy, :move ]
  layout -> { ::Views::Layouts::AppLayout.new(pathname: request.path) }

  def destroy
    @journal = @prompt.journal

    # Remove from journal's descendant
    @journal.descendant.remove_active_record("JournalPrompt", @prompt.id)
    @journal.descendant.remove_inactive_record("JournalPrompt", @prompt.id)
    @journal.descendant.save!

    # Destroy prompt (cascade deletes fragments)
    @prompt.destroy!

    # Rebuild tree
    tree = ::ItemTree::Build.call(@journal.descendant, root_label: "journal")

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(
            "journal_tree",
            render_to_string(::Views::Journals::JournalTree.new(journal: @journal, tree: tree), layout: false)
          ),
          turbo_stream.append("body", "<script>window.toast && window.toast('Prompt deleted successfully', { type: 'success' });</script>")
        ]
      end
    end
  end

  def move
    @journal = @prompt.journal
    direction = params[:direction]

    # Get current position in journal's descendant
    tuple = { "JournalPrompt" => @prompt.id }
    current_items = @journal.descendant.active_items
    current_index = current_items.index(tuple)

    return head :unprocessable_entity unless current_index

    # Calculate new position
    new_index = direction == "up" ? current_index - 1 : current_index + 1

    # Check boundaries
    return head :unprocessable_entity if new_index < 0 || new_index >= current_items.length

    # Swap positions
    new_items = current_items.dup
    new_items[current_index], new_items[new_index] = new_items[new_index], new_items[current_index]

    @journal.descendant.reorder_active_items(new_items)
    @journal.descendant.save!

    # Rebuild tree
    tree = ::ItemTree::Build.call(@journal.descendant, root_label: "journal")

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "journal_tree",
          render_to_string(::Views::Journals::JournalTree.new(journal: @journal, tree: tree), layout: false)
        )
      end
    end
  end

  private

  def set_prompt
    @prompt = current_user.journal_prompts.find(params[:id])
  end

  def prompt_params
    params.require(:journal_prompt).permit(:prompt_text)
  end
end
