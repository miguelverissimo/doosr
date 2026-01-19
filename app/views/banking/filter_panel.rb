# frozen_string_literal: true

module Views
  module Banking
    class FilterPanel < ::Views::Base
      def initialize(
        user:,
        start_date: nil,
        end_date: nil,
        category_id: nil,
        min_amount: nil,
        max_amount: nil,
        search: nil,
        sort_column: "date",
        sort_direction: "desc"
      )
        @user = user
        @start_date = start_date
        @end_date = end_date
        @category_id = category_id
        @min_amount = min_amount
        @max_amount = max_amount
        @search = search
        @sort_column = sort_column
        @sort_direction = sort_direction
        @categories = user.categories.order(:name)
      end

      def view_template
        div(
          id: "banking_filter_panel",
          class: "mb-4",
          data: { controller: "search-transactions" }
        ) do
          render_quick_date_filters

          form(
            action: view_context.banking_index_path,
            method: "get",
            data: {
              turbo_stream: true,
              action: "submit->transactions-pagination#showSpinner",
              search_transactions_target: "form"
            },
            class: "space-y-4"
          ) do
            input(type: :hidden, name: "sort", value: @sort_column)
            input(type: :hidden, name: "direction", value: @sort_direction)

            render_filter_fields
            render_action_buttons
          end
        end
      end

      private

      def render_filter_fields
        div(class: "grid grid-cols-2 md:grid-cols-6 gap-4") do
          render_search_field
          render_date_from_field
          render_date_to_field
          render_category_field
          render_min_amount_field
          render_max_amount_field
        end
      end

      def render_search_field
        div do
          label(class: "text-sm font-medium mb-1 block") { "Search" }
          render RubyUI::Input.new(
            type: :text,
            name: "search",
            placeholder: "Search descriptions...",
            value: @search,
            data: {
              action: "input->search-transactions#search"
            }
          )
        end
      end

      def render_date_from_field
        div do
          label(class: "text-sm font-medium mb-1 block") { "Date From" }
          render RubyUI::Input.new(
            type: :date,
            name: "start_date",
            class: "date-input-icon-light-dark",
            value: @start_date&.to_s
          )
        end
      end

      def render_date_to_field
        div do
          label(class: "text-sm font-medium mb-1 block") { "Date To" }
          render RubyUI::Input.new(
            type: :date,
            name: "end_date",
            class: "date-input-icon-light-dark",
            value: @end_date&.to_s
          )
        end
      end

      def render_category_field
        div do
          label(class: "text-sm font-medium mb-1 block") { "Category" }
          select(
            name: "category_id",
            class: "flex h-9 w-full rounded-md border bg-background px-3 py-1 text-sm shadow-sm transition-colors border-border focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
          ) do
            option(value: "") { "All Categories" }
            option(value: "uncategorized", selected: @category_id == "uncategorized") { "Uncategorized" }
            @categories.each do |category|
              option(
                value: category.id,
                selected: @category_id.to_s == category.id.to_s
              ) { category.name }
            end
          end
        end
      end

      def render_min_amount_field
        div do
          label(class: "text-sm font-medium mb-1 block") { "Min Amount" }
          render RubyUI::Input.new(
            type: :number,
            name: "min_amount",
            placeholder: "0.00",
            step: "0.01",
            value: @min_amount
          )
        end
      end

      def render_max_amount_field
        div do
          label(class: "text-sm font-medium mb-1 block") { "Max Amount" }
          render RubyUI::Input.new(
            type: :number,
            name: "max_amount",
            placeholder: "0.00",
            step: "0.01",
            value: @max_amount
          )
        end
      end

      def render_action_buttons
        div(class: "flex items-center gap-2") do
          render_active_filter_badge
          Button(variant: :primary, type: :submit) { "Apply Filters" }
          render_clear_filters_button if any_filters_active?
        end
      end

      def render_active_filter_badge
        count = active_filter_count
        return if count.zero?

        span(
          class: "inline-flex items-center rounded-full bg-primary/10 px-2.5 py-0.5 text-xs font-medium text-primary"
        ) { "#{count} active filter#{'s' if count > 1}" }
      end

      def render_clear_filters_button
        a(
          href: view_context.banking_index_path(
            sort: @sort_column,
            direction: @sort_direction
          ),
          data: {
            turbo_stream: true,
            action: "click->transactions-pagination#showSpinner"
          },
          class: "inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors h-9 px-4 py-2 border border-input bg-background hover:bg-accent hover:text-accent-foreground"
        ) { "Clear Filters" }
      end

      def any_filters_active?
        @category_id.present? || @min_amount.present? || @max_amount.present? || @search.present? || non_default_date_range?
      end

      def non_default_date_range?
        default_start = Date.current.beginning_of_month
        default_end = Date.current.end_of_month
        @start_date != default_start || @end_date != default_end
      end

      def active_filter_count
        count = 0
        count += 1 if non_default_date_range?
        count += 1 if @category_id.present?
        count += 1 if @min_amount.present?
        count += 1 if @max_amount.present?
        count += 1 if @search.present?
        count
      end

      def render_quick_date_filters
        div(class: "flex flex-wrap gap-2 mb-4") do
          quick_date_options.each do |option|
            render_quick_date_button(option)
          end
          render_uncategorized_filter_button
        end
      end

      def quick_date_options
        today = Date.current
        [
          {
            label: "This Month",
            start_date: today.beginning_of_month,
            end_date: today.end_of_month
          },
          {
            label: "Last Month",
            start_date: today.last_month.beginning_of_month,
            end_date: today.last_month.end_of_month
          },
          {
            label: "Last 3 Months",
            start_date: (today - 3.months).beginning_of_month,
            end_date: today.end_of_month
          },
          {
            label: "This Year",
            start_date: today.beginning_of_year,
            end_date: today.end_of_year
          },
          {
            label: "All Time",
            start_date: nil,
            end_date: nil
          }
        ]
      end

      def render_quick_date_button(option)
        is_active = quick_filter_active?(option)

        button_class = if is_active
          "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors h-8 px-3 py-1 bg-primary text-primary-foreground"
        else
          "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors h-8 px-3 py-1 border border-input bg-background hover:bg-accent hover:text-accent-foreground"
        end

        url_params = {
          sort: @sort_column,
          direction: @sort_direction,
          category_id: @category_id,
          min_amount: @min_amount,
          max_amount: @max_amount,
          search: @search
        }.compact_blank

        if option[:start_date]
          url_params[:start_date] = option[:start_date].to_s
          url_params[:end_date] = option[:end_date].to_s
        else
          url_params[:start_date] = "all"
          url_params[:end_date] = "all"
        end

        a(
          href: view_context.banking_index_path(url_params),
          class: button_class,
          data: {
            turbo_stream: true,
            action: "click->transactions-pagination#showSpinner"
          }
        ) { option[:label] }
      end

      def quick_filter_active?(option)
        if option[:start_date].nil?
          @start_date.nil? && @end_date.nil?
        else
          @start_date == option[:start_date] && @end_date == option[:end_date]
        end
      end

      def render_uncategorized_filter_button
        is_active = @category_id == "uncategorized"

        button_class = if is_active
          "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors h-8 px-3 py-1 bg-primary text-primary-foreground"
        else
          "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors h-8 px-3 py-1 border border-input bg-background hover:bg-accent hover:text-accent-foreground"
        end

        url_params = {
          sort: @sort_column,
          direction: @sort_direction,
          min_amount: @min_amount,
          max_amount: @max_amount,
          search: @search
        }.compact_blank

        url_params[:start_date] = @start_date.to_s if @start_date.present?
        url_params[:end_date] = @end_date.to_s if @end_date.present?

        if is_active
          # Clear the filter
        else
          url_params[:category_id] = "uncategorized"
        end

        a(
          href: view_context.banking_index_path(url_params),
          class: button_class,
          data: {
            turbo_stream: true,
            action: "click->transactions-pagination#showSpinner"
          }
        ) { "Uncategorized" }
      end
    end
  end
end
