# frozen_string_literal: true

class DayPaymentRemindersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_day_payment_reminder, only: [:actions_sheet, :move, :destroy, :mark_paid]
  layout -> { ::Views::Layouts::AppLayout.new(pathname: request.path) }

  def actions_sheet
    @day = current_user.days.find(params[:day_id]) if params[:day_id].present?
    @list = current_user.lists.find(params[:list_id]) if params[:list_id].present?

    # Get day payment reminder index and total for move buttons
    if @day
      descendant = @day.descendant
      reminder_ids = descendant.extract_active_ids_by_type("DayPaymentReminder")
      @reminder_index = reminder_ids.index(@day_payment_reminder.id)
      @total_reminders = reminder_ids.length
    elsif @list
      descendant = @list.descendant
      reminder_ids = descendant.extract_active_ids_by_type("DayPaymentReminder")
      @reminder_index = reminder_ids.index(@day_payment_reminder.id)
      @total_reminders = reminder_ids.length
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(
          "body",
          render_to_string(::Views::DayPaymentReminders::ActionsSheet.new(
            day_payment_reminder: @day_payment_reminder,
            day: @day,
            list: @list,
            reminder_index: @reminder_index,
            total_reminders: @total_reminders
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

    # Find reminder tuple in active_items
    reminder_tuple = { "DayPaymentReminder" => @day_payment_reminder.id }
    current_index = descendant.active_items.index(reminder_tuple)
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

        # Reload to get fresh data
        if @day
          @day = current_user.days.includes(:descendant).find(@day.id)
          @day.descendant.reload
          
          # Build tree ONCE using ItemTree::Build
          tree = ::ItemTree::Build.call(@day.descendant, root_label: "day")
          
          # Render tree nodes from the pre-built tree
          rendered_items = tree.children.map do |node|
            render_to_string(::Views::Items::TreeNode.new(node: node, day: @day), layout: false)
          end.join
        elsif @list
          @list = current_user.lists.includes(:descendant).find(@list.id)
          @list.descendant.reload
          
          # Build tree ONCE using ItemTree::Build
          tree = ::ItemTree::Build.call(@list.descendant, root_label: "list")
          
          # Render tree nodes from the pre-built tree
          rendered_items = tree.children.map do |node|
            render_to_string(::Views::Items::TreeNode.new(node: node, context: @list), layout: false)
          end.join
        else
          return head :unprocessable_entity
        end

        render turbo_stream: turbo_stream.update("items_list", rendered_items)
      end
    end
  end

  def mark_paid
    @day = current_user.days.find(params[:day_id]) if params[:day_id].present?
    @list = current_user.lists.find(params[:list_id]) if params[:list_id].present?

    @day_payment_reminder.mark_paid!

    respond_to do |format|
      format.turbo_stream do
        # Reload to get fresh data after marking as paid
        if @day
          @day = current_user.days.includes(:descendant).find(@day.id)
          @day.descendant.reload
          
          # Build tree ONCE using ItemTree::Build
          tree = ::ItemTree::Build.call(@day.descendant, root_label: "day")
          
          # Render tree nodes from the pre-built tree
          rendered_items = tree.children.map do |node|
            render_to_string(::Views::Items::TreeNode.new(node: node, day: @day), layout: false)
          end.join
        elsif @list
          @list = current_user.lists.includes(:descendant).find(@list.id)
          @list.descendant.reload
          
          # Build tree ONCE using ItemTree::Build
          tree = ::ItemTree::Build.call(@list.descendant, root_label: "list")
          
          # Render tree nodes from the pre-built tree
          rendered_items = tree.children.map do |node|
            render_to_string(::Views::Items::TreeNode.new(node: node, context: @list), layout: false)
          end.join
        else
          return head :unprocessable_entity
        end

        render turbo_stream: [
          turbo_stream.remove("day_payment_reminder_actions_sheet"),
          turbo_stream.update("items_list", rendered_items),
          turbo_stream.append("body", "<script>window.toast && window.toast('Payment marked as paid', { type: 'success' });</script>")
        ]
      end
      format.html { redirect_to @day ? day_path(@day) : list_path(@list) }
    end
  end

  def destroy
    @day = current_user.days.find(params[:day_id]) if params[:day_id].present?
    @list = current_user.lists.find(params[:list_id]) if params[:list_id].present?

    descendant = @day&.descendant || @list&.descendant
    if descendant
      # Remove from descendant
      descendant.remove_active_record("DayPaymentReminder", @day_payment_reminder.id)
      descendant.save!
    end

    @day_payment_reminder.destroy!

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove("day_payment_reminder_actions_sheet"),
          turbo_stream.remove("day_payment_reminder_#{@day_payment_reminder.id}"),
          turbo_stream.append("body", "<script>window.toast && window.toast('Payment reminder removed', { type: 'success' });</script>")
        ]
      end
    end
  end

  private

  def set_day_payment_reminder
    @day_payment_reminder = current_user.day_payment_reminders.find(params[:id])
  end
end
