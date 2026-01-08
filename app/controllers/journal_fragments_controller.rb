# frozen_string_literal: true

class JournalFragmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_fragment, only: [ :edit, :update, :destroy, :move ]
  layout -> { ::Views::Layouts::AppLayout.new(pathname: request.path) }

  def new
    @journal = current_user.journals.find(params[:journal_id])
    @fragment = current_user.journal_fragments.build
    @prompt = params[:prompt_id].present? ? current_user.journal_prompts.find(params[:prompt_id]) : nil

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(
          "body",
          render_to_string(::Views::JournalFragments::FormDialog.new(fragment: @fragment, journal: @journal, prompt: @prompt))
        )
      end
    end
  end

  def create
    @journal = current_user.journals.find(params[:journal_id])
    @fragment = current_user.journal_fragments.build(fragment_params)
    @fragment.journal = @journal

    # Determine parent (journal or prompt)
    parent_descendant = if params[:prompt_id].present?
      prompt = current_user.journal_prompts.find(params[:prompt_id])
      prompt.descendant
    else
      @journal.descendant
    end

    if @fragment.save
      # Add to parent's descendant
      parent_descendant.add_active_record("JournalFragment", @fragment.id)
      parent_descendant.save!

      # Rebuild tree
      tree = ::ItemTree::Build.call(@journal.descendant, root_label: "journal")

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove("fragment_dialog"),
            turbo_stream.replace(
              "journal_tree",
              render_to_string(::Views::Journals::JournalTree.new(journal: @journal, tree: tree), layout: false)
            ),
            turbo_stream.append("body", "<script>window.toast && window.toast('Fragment created successfully', { type: 'success' });</script>")
          ]
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "fragment_form_errors",
            "<div class='text-sm text-destructive'>#{@fragment.errors.full_messages.join(', ')}</div>"
          ), status: :unprocessable_entity
        end
      end
    end
  end

  def edit
    @journal = @fragment.journal

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(
          "body",
          render_to_string(::Views::JournalFragments::FormDialog.new(fragment: @fragment, journal: @journal))
        )
      end
    end
  end

  def update
    @journal = @fragment.journal

    if @fragment.update(fragment_params)
      # Rebuild tree
      tree = ::ItemTree::Build.call(@journal.descendant, root_label: "journal")

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove("fragment_dialog"),
            turbo_stream.replace(
              "journal_tree",
              render_to_string(::Views::Journals::JournalTree.new(journal: @journal, tree: tree), layout: false)
            ),
            turbo_stream.append("body", "<script>window.toast && window.toast('Fragment updated successfully', { type: 'success' });</script>")
          ]
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "fragment_form_errors",
            "<div class='text-sm text-destructive'>#{@fragment.errors.full_messages.join(', ')}</div>"
          ), status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    @journal = @fragment.journal

    # Remove from all parent descendants
    @fragment.parent_descendants.each do |descendant|
      descendant.remove_active_record("JournalFragment", @fragment.id)
      descendant.remove_inactive_record("JournalFragment", @fragment.id)
      descendant.save!
    end

    @fragment.destroy!

    # Rebuild tree
    tree = ::ItemTree::Build.call(@journal.descendant, root_label: "journal")

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(
            "journal_tree",
            render_to_string(::Views::Journals::JournalTree.new(journal: @journal, tree: tree), layout: false)
          ),
          turbo_stream.append("body", "<script>window.toast && window.toast('Fragment deleted successfully', { type: 'success' });</script>")
        ]
      end
    end
  end

  def move
    @journal = @fragment.journal
    direction = params[:direction]

    # Find parent descendant
    parent_descendant = @fragment.parent_descendants.first
    return head :unprocessable_entity unless parent_descendant

    # Get current position
    tuple = { "JournalFragment" => @fragment.id }
    current_items = parent_descendant.active_items
    current_index = current_items.index(tuple)

    return head :unprocessable_entity unless current_index

    # Calculate new position
    new_index = direction == "up" ? current_index - 1 : current_index + 1

    # Check boundaries
    return head :unprocessable_entity if new_index < 0 || new_index >= current_items.length

    # Swap positions
    new_items = current_items.dup
    new_items[current_index], new_items[new_index] = new_items[new_index], new_items[current_index]

    parent_descendant.reorder_active_items(new_items)
    parent_descendant.save!

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

  def set_fragment
    @fragment = current_user.journal_fragments.find(params[:id])
  end

  def fragment_params
    params.require(:journal_fragment).permit(:content)
  end
end
