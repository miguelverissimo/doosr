# frozen_string_literal: true

module Banking
  class PlannedExpensesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_planned_expense, only: [ :edit, :update, :destroy, :mark_completed ]
    layout -> { ::Views::Layouts::AppLayout.new(pathname: request.path) if request.format.html? }

    def index
      @planned_expenses = current_user.planned_expenses
        .includes(:category, :recurring_group)
        .order(due_date: :asc)
      @categories = current_user.categories.order(:name)

      respond_to do |format|
        format.html { redirect_to banking_forecasts_path }
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(
            "body",
            render_to_string(::Views::Banking::PlannedExpenses::IndexDialog.new(
              planned_expenses: @planned_expenses,
              categories: @categories
            ), layout: false)
          )
        end
      end
    end

    def new
      @planned_expense = current_user.planned_expenses.build(due_date: Date.current)
      @categories = current_user.categories.order(:name)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(
            "body",
            render_to_string(::Views::Banking::PlannedExpenses::FormDialog.new(
              planned_expense: @planned_expense,
              categories: @categories
            ), layout: false)
          )
        end
      end
    end

    def create
      @planned_expense = current_user.planned_expenses.build(planned_expense_params)
      @planned_expense.expense_type = "one_time"

      if @planned_expense.save
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.remove("planned_expense_form_dialog"),
              turbo_stream.replace(
                "planned_expenses_list",
                render_to_string(::Views::Banking::PlannedExpenses::List.new(
                  planned_expenses: upcoming_expenses
                ), layout: false)
              ),
              turbo_stream.replace(
                "planned_expenses_content",
                render_to_string(::Views::Banking::PlannedExpenses::TabsContent.new(
                  planned_expenses: all_expenses
                ), layout: false)
              )
            ]
          end
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "planned_expense_form_errors",
              "<div class='text-sm text-destructive'>#{@planned_expense.errors.full_messages.join(', ')}</div>"
            ), status: :unprocessable_entity
          end
        end
      end
    end

    def edit
      @categories = current_user.categories.order(:name)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(
            "body",
            render_to_string(::Views::Banking::PlannedExpenses::FormDialog.new(
              planned_expense: @planned_expense,
              categories: @categories
            ), layout: false)
          )
        end
      end
    end

    def update
      if @planned_expense.update(planned_expense_params)
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.remove("planned_expense_form_dialog"),
              turbo_stream.replace(
                "planned_expenses_list",
                render_to_string(::Views::Banking::PlannedExpenses::List.new(
                  planned_expenses: upcoming_expenses
                ), layout: false)
              ),
              turbo_stream.replace(
                "planned_expenses_content",
                render_to_string(::Views::Banking::PlannedExpenses::TabsContent.new(
                  planned_expenses: all_expenses
                ), layout: false)
              )
            ]
          end
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "planned_expense_form_errors",
              "<div class='text-sm text-destructive'>#{@planned_expense.errors.full_messages.join(', ')}</div>"
            ), status: :unprocessable_entity
          end
        end
      end
    end

    def destroy
      @planned_expense.destroy!

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove("planned_expense_#{@planned_expense.id}"),
            turbo_stream.replace(
              "planned_expenses_list",
              render_to_string(::Views::Banking::PlannedExpenses::List.new(
                planned_expenses: upcoming_expenses
              ), layout: false)
            ),
            turbo_stream.replace(
              "planned_expenses_content",
              render_to_string(::Views::Banking::PlannedExpenses::TabsContent.new(
                planned_expenses: all_expenses
              ), layout: false)
            )
          ]
        end
      end
    end

    def mark_completed
      @planned_expense.mark_completed!

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(
              "planned_expense_#{@planned_expense.id}",
              render_to_string(::Views::Banking::PlannedExpenses::ExpenseRow.new(
                planned_expense: @planned_expense
              ), layout: false)
            ),
            turbo_stream.replace(
              "planned_expenses_list",
              render_to_string(::Views::Banking::PlannedExpenses::List.new(
                planned_expenses: upcoming_expenses
              ), layout: false)
            ),
            turbo_stream.replace(
              "planned_expenses_content",
              render_to_string(::Views::Banking::PlannedExpenses::TabsContent.new(
                planned_expenses: all_expenses
              ), layout: false)
            )
          ]
        end
      end
    end

    def populate_from_recurring
      result = ::Banking::PlannedExpensePopulatorService.new(current_user).call

      respond_to do |format|
        if result.success
          format.turbo_stream do
            flash.now[:notice] = "Created #{result.created_count} planned expenses from recurring transactions"
            render turbo_stream: [
              turbo_stream.replace(
                "flash_messages",
                render_to_string(::Views::Shared::FlashMessages.new(flash: flash), layout: false)
              ),
              turbo_stream.replace(
                "planned_expenses_list",
                render_to_string(::Views::Banking::PlannedExpenses::List.new(
                  planned_expenses: upcoming_expenses
                ), layout: false)
              ),
              turbo_stream.replace(
                "planned_expenses_content",
                render_to_string(::Views::Banking::PlannedExpenses::TabsContent.new(
                  planned_expenses: all_expenses
                ), layout: false)
              )
            ]
          end
        else
          format.turbo_stream do
            flash.now[:alert] = result.errors.join(", ")
            render turbo_stream: turbo_stream.replace(
              "flash_messages",
              render_to_string(::Views::Shared::FlashMessages.new(flash: flash), layout: false)
            ), status: :unprocessable_entity
          end
        end
      end
    end

    private

    def set_planned_expense
      @planned_expense = current_user.planned_expenses.find(params[:id])
    end

    def planned_expense_params
      params.require(:planned_expense).permit(:description, :expected_amount, :due_date, :category_id, :completed)
    end

    def upcoming_expenses
      current_user.planned_expenses
        .where(completed: false)
        .where("due_date >= ?", Date.current)
        .order(due_date: :asc)
    end

    def all_expenses
      current_user.planned_expenses
        .includes(:category, :recurring_group)
        .order(due_date: :asc)
    end
  end
end
