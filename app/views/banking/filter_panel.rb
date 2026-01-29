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
        sort_direction: "desc",
        bank_account_id: nil,
        transfer_filter: "exclude"
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
        @bank_account_id = bank_account_id
        @transfer_filter = transfer_filter
        @categories = user.categories.top_level.with_subcategories.order(:name)
        @bank_accounts = user.bank_accounts.ordered
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
              action: "submit->transactions-pagination#showSpinner",
              search_transactions_target: "form"
            },
            class: "space-y-4"
          ) do
            input(type: :hidden, name: "sort", value: @sort_column)
            input(type: :hidden, name: "direction", value: @sort_direction)

            div(class: "mb-2") do
              span(class: "text-sm font-medium text-muted-foreground") { "Filters" }
            end
            render_filter_fields
            render_action_buttons
          end
        end
      end

      private

      def render_filter_fields
        div(class: "grid grid-cols-2 md:grid-cols-4 gap-4") do
          render_search_field
          render_date_from_field
          render_date_to_field
          render_category_field
        end
        div(class: "grid grid-cols-2 md:grid-cols-4 gap-4 mt-4") do
          render_bank_account_field
          render_transfer_filter_field
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
            render_hierarchical_category_options
          end
        end
      end

      def render_hierarchical_category_options
        @categories.each do |category|
          # Use .size on preloaded association to avoid queries
          if category.subcategories.size > 0
            optgroup(label: category.name) do
              option(
                value: category.id,
                selected: @category_id.to_s == category.id.to_s
              ) { category.name }

              # Sort in Ruby to avoid query - subcategories already preloaded
              category.subcategories.sort_by(&:name).each do |sub|
                option(
                  value: sub.id,
                  selected: @category_id.to_s == sub.id.to_s
                ) { "  └ #{sub.name}" }
              end
            end
          else
            option(
              value: category.id,
              selected: @category_id.to_s == category.id.to_s
            ) { category.name }
          end
        end
      end

      def render_bank_account_field
        div do
          label(class: "text-sm font-medium mb-1 block") { "Account" }
          select(
            name: "bank_account_id",
            class: "flex h-9 w-full rounded-md border bg-background px-3 py-1 text-sm shadow-sm transition-colors border-border focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
          ) do
            option(value: "") { "All Accounts" }
            option(value: "none", selected: @bank_account_id == "none") { "Unassigned" }
            @bank_accounts.each do |account|
              option(
                value: account.id,
                selected: @bank_account_id.to_s == account.id.to_s
              ) { account.name }
            end
          end
        end
      end

      def render_transfer_filter_field
        div do
          label(class: "text-sm font-medium mb-1 block") { "Transfers" }
          select(
            name: "transfer_filter",
            class: "flex h-9 w-full rounded-md border bg-background px-3 py-1 text-sm shadow-sm transition-colors border-border focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
          ) do
            option(value: "exclude", selected: @transfer_filter == "exclude") { "Exclude Transfers" }
            option(value: "all", selected: @transfer_filter == "all") { "Include All" }
            option(value: "only", selected: @transfer_filter == "only") { "Transfers Only" }
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
          Button(variant: :primary, size: :sm, type: :submit) { "Apply Filters" }
          render_clear_filters_button if any_filters_active?
          render_active_filter_badge
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
        render ::Components::ColoredLink.new(
          href: view_context.banking_index_path(
            sort: @sort_column,
            direction: @sort_direction
          ),
          data: {
            action: "click->transactions-pagination#showSpinner"
          },
          variant: :outline,
          size: :sm,
        ) { "Clear Filters" }
      end

      def any_filters_active?
        @category_id.present? || @min_amount.present? || @max_amount.present? || @search.present? || non_default_date_range? || @bank_account_id.present? || @transfer_filter != "exclude"
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
        count += 1 if @bank_account_id.present?
        count += 1 if @transfer_filter != "exclude"
        count
      end

      def render_quick_date_filters
        div(class: "flex flex-wrap gap-2 mb-4") do
          quick_date_options.each do |option|
            render_quick_date_button(option)
          end
          render_uncategorized_filter_button
        end
        render_account_quick_filters if @bank_accounts.any?
      end

      def render_account_quick_filters
        div(class: "flex flex-wrap gap-2 mb-4") do
          render_all_accounts_button
          @bank_accounts.each do |account|
            render_account_filter_button(account)
          end
        end
      end

      def render_all_accounts_button
        is_active = @bank_account_id.blank?
        variant = is_active ? :orange : :outline

        url_params = base_filter_params.merge(bank_account_id: nil)

        render ::Components::ColoredLink.new(
          href: view_context.banking_index_path(url_params),
          variant: variant,
          size: :sm,
          data: {
            action: "click->transactions-pagination#showSpinner"
          }
        ) { "All Accounts" }
      end

      def render_account_filter_button(account)
        is_active = @bank_account_id.to_s == account.id.to_s

        url_params = base_filter_params.merge(
          bank_account_id: is_active ? nil : account.id
        )

        button_class = if is_active
          "inline-flex items-center gap-1.5 h-8 px-3 py-1 rounded-md text-sm font-medium ring-2 ring-primary ring-offset-2"
        else
          "inline-flex items-center gap-1.5 h-8 px-3 py-1 rounded-md text-sm font-medium border border-input bg-background hover:bg-accent hover:text-accent-foreground"
        end

        a(
          href: view_context.banking_index_path(url_params),
          class: button_class,
          data: {
            action: "click->transactions-pagination#showSpinner"
          }
        ) do
          div(
            class: "inline-flex items-center justify-center w-5 h-5 rounded-full text-[10px] font-bold",
            style: "background-color: #{account.bg_color}; color: #{account.fg_color};"
          ) do
            plain account.display_letter
          end
          span { account.name }
        end
      end

      def base_filter_params
        {
          sort: @sort_column,
          direction: @sort_direction,
          category_id: @category_id,
          min_amount: @min_amount,
          max_amount: @max_amount,
          search: @search,
          transfer_filter: @transfer_filter,
          start_date: @start_date&.to_s,
          end_date: @end_date&.to_s
        }.compact_blank
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
            label: "Last 12 Months",
            start_date: (today - 11.months).beginning_of_month,
            end_date: today
          },
          {
            label: "This Year",
            start_date: today.beginning_of_year,
            end_date: today.end_of_year
          },
          {
            label: "Last Year",
            start_date: today.last_year.beginning_of_year,
            end_date: today.last_year.end_of_year
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

        variant = is_active ? :orange : :outline

        url_params = {
          sort: @sort_column,
          direction: @sort_direction,
          category_id: @category_id,
          min_amount: @min_amount,
          max_amount: @max_amount,
          search: @search,
          bank_account_id: @bank_account_id,
          transfer_filter: @transfer_filter
        }.compact_blank

        if option[:start_date]
          url_params[:start_date] = option[:start_date].to_s
          url_params[:end_date] = option[:end_date].to_s
        else
          url_params[:start_date] = "all"
          url_params[:end_date] = "all"
        end

        render ::Components::ColoredLink.new(
          href: view_context.banking_index_path(url_params),
          size: :sm,
          variant: variant,
          data: {
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

        variant = is_active ? :orange : :outline

        url_params = {
          sort: @sort_column,
          direction: @sort_direction,
          min_amount: @min_amount,
          max_amount: @max_amount,
          search: @search,
          bank_account_id: @bank_account_id,
          transfer_filter: @transfer_filter
        }.compact_blank

        url_params[:start_date] = @start_date.to_s if @start_date.present?
        url_params[:end_date] = @end_date.to_s if @end_date.present?

        if is_active
          # Clear the filter
        else
          url_params[:category_id] = "uncategorized"
        end

        render ::Components::ColoredLink.new(
          href: view_context.banking_index_path(url_params),
          variant: variant,
          size: :sm,
          data: {
            action: "click->transactions-pagination#showSpinner"
          }
        ) { "Uncategorized" }
      end
    end
  end
end
