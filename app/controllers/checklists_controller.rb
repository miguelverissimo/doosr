class ChecklistsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_checklist, only: [ :show, :update, :destroy, :complete_item, :reset ]
  layout -> { ::Views::Layouts::AppLayout.new(pathname: request.path, checklist: @checklist) }

  def index
    @checklist_templates = current_user.checklists.template
    render ::Views::Checklists::Index.new(checklist_templates: @checklist_templates)
  end

  def show
    render ::Views::Checklists::Show.new(checklist: @checklist)
  end

  def complete_item
    item_index = params[:item_index].to_i
    items = @checklist.items.dup

    # Toggle completion on the item itself
    if items[item_index]
      item = items[item_index]
      if item["completed_at"].present?
        item["completed_at"] = nil
      else
        item["completed_at"] = Time.current.iso8601
      end
      items[item_index] = item
    end

    # Update metadata for overall checklist tracking
    metadata = @checklist.metadata.dup
    completed_count = items.count { |item| item["completed_at"].present? }

    # Set started_at if first completion
    metadata["started_at"] ||= Time.current.iso8601 if completed_count > 0

    # Set completed_at if all items done
    if completed_count == items.length
      metadata["completed_at"] = Time.current.iso8601
    else
      metadata["completed_at"] = nil
    end

    @checklist.update!(items: items, metadata: metadata)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "checklist_content",
          ::Views::Checklists::Content.new(checklist: @checklist)
        )
      end
    end
  end

  def reset
    # Clear completed_at from all items
    items = @checklist.items.dup
    items.each do |item|
      item["completed_at"] = nil
    end

    # Clear metadata
    metadata = @checklist.metadata.dup
    metadata["started_at"] = nil
    metadata["completed_at"] = nil

    @checklist.update!(items: items, metadata: metadata)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "checklist_content",
          ::Views::Checklists::Content.new(checklist: @checklist)
        )
      end
    end
  end

  def create
    @checklist_template = current_user.checklists.build(checklist_params)
    @checklist_template.kind = "template" # Ensure it's a template

    respond_to do |format|
      if @checklist_template.save
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("checklists_list", ::Views::Checklists::ListContent.new(user: current_user)),
            turbo_stream.append("body", "<script>window.toast && window.toast('Checklist template created successfully', { type: 'success' });</script>")
          ]
        end
        format.html { redirect_to checklists_path, notice: "Checklist template created successfully." }
      else
        format.turbo_stream do
          error_message = @checklist_template.errors.full_messages.join(", ")
          render turbo_stream: turbo_stream.append("body", "<script>window.toast && window.toast('Failed to create checklist template: #{error_message}', { type: 'error' });</script>")
        end
        format.html { redirect_to checklists_path, alert: "Failed to create checklist template" }
      end
    end
  end

  def update
    respond_to do |format|
      if @checklist.update(checklist_params)
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("checklist_#{@checklist.id}_div", ::Views::Checklists::TemplateRow.new(checklist: @checklist)),
            turbo_stream.append("body", "<script>window.toast && window.toast('Checklist template updated successfully', { type: 'success' });</script>")
          ]
        end
        format.html { redirect_to checklists_path, notice: "Checklist template updated successfully." }
      else
        format.turbo_stream do
          error_message = @checklist.errors.full_messages.join(", ")
          render turbo_stream: turbo_stream.append("body", "<script>window.toast && window.toast('Failed to update checklist template: #{error_message}', { type: 'error' });</script>")
        end
        format.html { redirect_to checklists_path, alert: "Failed to update checklist template" }
      end
    end
  end

  def destroy
  end

  private

  def set_checklist
    @checklist = current_user.checklists.find(params[:id])
  end

  def checklist_params
    params.require(:checklist).permit(:name, :description, :kind, :template_id, :flow, :items, :metadata)
  end
end
