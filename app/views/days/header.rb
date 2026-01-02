# frozen_string_literal: true

module Views
  module Days
    class Header < ::Views::Base
      def initialize(date:, day: nil, latest_importable_day: nil)
        @date = date
        @day = day
        @latest_importable_day = latest_importable_day
      end

      def view_template
        # Date display with import status
        div do
            h1(class: "font-semibold text-base") { full_date }
            p(class: "text-sm") do
              # Fixed Calendar date
              render_fixed_calendar_date_link

              # Import status in muted color
              if @day&.imported_from_day
                span(class: "text-muted-foreground text-xs") do
                  plain " • Imported from #{format_date(@day.imported_from_day.date)}"
                end
              end

              if @day&.imported_to_day
                span(class: "text-muted-foreground text-xs") do
                  plain " • Imported to #{format_date(@day.imported_to_day.date)}"
                end
              end
            end
          end

        # Spacer
        div(class: "flex-1")

        # Day state badge
        render_state_badge

        # Three-dot menu
        render_actions_menu
      end

      private

      def full_date
        # Format: "Friday, January 2, 2026"
        @date.strftime("%A, %B %-d, %Y")
      end

      def render_fixed_calendar_date_link
        # @date = Date.new(2026, 1, 18)
        converter = ::FixedCalendar::Converter.new(@date)
        case converter.has_ritual?
        when true
          render Components::ColoredLink.new(href: view_context.fixed_calendar_path(date: @date, open_ritual: true), variant: :ghost_rose, size: :md, plain: true) do
            converter.to_formatted_string
          end
        when false
          render Components::ColoredLink.new(href: view_context.fixed_calendar_path(date: @date), variant: :ghost_sky, size: :md, plain: true) do
            converter.to_formatted_string
          end
        end
      end

      def format_date(date)
        # Format dates using UTC to prevent timezone issues
        # Format: "Nov 19, 2025"
        date.strftime("%b %-d, %Y")
      end

      def render_state_badge
        badge_text = if @day.nil?
          "Empty"
        elsif @day.open?
          "Open"
        elsif @day.closed?
          "Closed"
        else
          "Unknown"
        end

        badge_variant = if @day.nil?
          :secondary
        elsif @day.open?
          :default
        elsif @day.closed?
          :outline
        else
          :secondary
        end

        Badge(variant: badge_variant, class: "text-xs") { badge_text }
      end

      def render_actions_menu
        render RubyUI::DropdownMenu.new do
          render RubyUI::DropdownMenuTrigger.new do
            Button(variant: :ghost, icon: true, size: :sm) do
              # Three dots icon
              svg(
                xmlns: "http://www.w3.org/2000/svg",
                class: "h-4 w-4",
                viewBox: "0 0 24 24",
                fill: "none",
                stroke: "currentColor",
                stroke_width: "2",
                stroke_linecap: "round",
                stroke_linejoin: "round"
              ) do |s|
                s.circle(cx: "12", cy: "12", r: "1")
                s.circle(cx: "12", cy: "5", r: "1")
                s.circle(cx: "12", cy: "19", r: "1")
              end
            end
          end

          render RubyUI::DropdownMenuContent.new(align: "end") do
            # Show "Open day" if day doesn't exist
            if @day.nil?
              form(action: view_context.days_path, method: "post", class: "w-full") do
                raw view_context.hidden_field_tag(:authenticity_token, view_context.form_authenticity_token)
                raw view_context.hidden_field_tag(:date, @date.to_s)
                button(
                  type: "submit",
                  class: "w-full text-left px-2 py-1.5 text-sm cursor-pointer hover:bg-accent rounded-sm"
                ) do
                  plain "Open day"
                end
              end
            end

            # Show "Close day" if day is open
            if @day&.open?
              form(action: view_context.close_day_path(@day), method: "post", class: "w-full", data: { turbo_method: "patch" }) do
                raw view_context.hidden_field_tag(:_method, "patch")
                raw view_context.hidden_field_tag(:authenticity_token, view_context.form_authenticity_token)
                button(
                  type: "submit",
                  class: "w-full text-left px-2 py-1.5 text-sm cursor-pointer hover:bg-accent rounded-sm"
                ) do
                  plain "Close day"
                end
              end
            end

            # Show "Re-open day" if day is closed
            if @day&.closed?
              form(action: view_context.reopen_day_path(@day), method: "post", class: "w-full", data: { turbo_method: "patch" }) do
                raw view_context.hidden_field_tag(:_method, "patch")
                raw view_context.hidden_field_tag(:authenticity_token, view_context.form_authenticity_token)
                button(
                  type: "submit",
                  class: "w-full text-left px-2 py-1.5 text-sm cursor-pointer hover:bg-accent rounded-sm"
                ) do
                  plain "Re-open day"
                end
              end
            end

            # Show "Add permanent sections" if day exists
            if @day
              form(
                action: view_context.add_permanent_sections_day_path(@day),
                method: "post",
                class: "w-full",
                data: { turbo_stream: true, turbo_method: "patch" }
              ) do
                raw view_context.hidden_field_tag(:_method, "patch")
                raw view_context.hidden_field_tag(:authenticity_token, view_context.form_authenticity_token)
                button(
                  type: "submit",
                  class: "w-full text-left px-2 py-1.5 text-sm cursor-pointer hover:bg-accent rounded-sm"
                ) do
                  plain "Add permanent sections"
                end
              end
            end

            # Show "Import from [date]" if latest importable day is available
            if @latest_importable_day
              a(
                href: view_context.new_day_migration_path(date: @date),
                data: {
                  turbo_frame: "day_migration_modal",
                  turbo_stream: true
                },
                class: "block w-full text-left px-2 py-1.5 text-sm cursor-pointer hover:bg-accent rounded-sm"
              ) do
                plain "Import from #{format_date(@latest_importable_day.date)}"
              end
            end
          end
        end
      end
    end
  end
end
