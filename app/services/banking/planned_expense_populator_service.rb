# frozen_string_literal: true

module Banking
  class PlannedExpensePopulatorService
    Result = Struct.new(:success, :created_count, :skipped_count, :errors, keyword_init: true)

    DEFAULT_WEEKS = 12

    def initialize(user, weeks: DEFAULT_WEEKS)
      @user = user
      @weeks = weeks
      @created_count = 0
      @skipped_count = 0
      @errors = []
    end

    def call
      populate_from_recurring_groups
      Result.new(
        success: @errors.empty?,
        created_count: @created_count,
        skipped_count: @skipped_count,
        errors: @errors
      )
    rescue StandardError => e
      Result.new(
        success: false,
        created_count: @created_count,
        skipped_count: @skipped_count,
        errors: ["Population failed: #{e.message}"]
      )
    end

    private

    def populate_from_recurring_groups
      @user.recurring_groups.active.expenses.each do |group|
        populate_for_group(group)
      end
    end

    def populate_for_group(group)
      future_dates = group.future_occurrences(weeks: @weeks)

      future_dates.each do |due_date|
        next if expense_exists_for_date?(group, due_date)

        create_planned_expense(group, due_date)
      end
    end

    def expense_exists_for_date?(group, due_date)
      @user.planned_expenses
        .where(recurring_group: group, due_date: due_date)
        .exists?
    end

    def create_planned_expense(group, due_date)
      @user.planned_expenses.create!(
        recurring_group: group,
        description: group.name,
        expected_amount: group.average_amount.abs,
        due_date: due_date,
        expense_type: "recurring_auto",
        completed: false
      )
      @created_count += 1
    rescue ActiveRecord::RecordInvalid => e
      @errors << "Failed to create expense for '#{group.name}' on #{due_date}: #{e.message}"
      @skipped_count += 1
    end
  end
end
