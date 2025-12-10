# frozen_string_literal: true

module Views
  module Days
    class Header < Views::Base
      def initialize(date:, day: nil, latest_importable_day: nil)
        @date = date
        @day = day
        @latest_importable_day = latest_importable_day
      end

      def view_template
        div(class: "flex items-center gap-3 flex-1") do
          # Date display with import status
          div do
            h1(class: "font-semibold text-base") { full_date }
            p(class: "text-xs") do
              # Weekday in normal color
              span(class: "text-foreground") { weekday }

              # Import status in muted color
              if @day&.imported_from_day
                span(class: "text-muted-foreground") do
                  plain " • Imported from #{format_date(@day.imported_from_day.date)}"
                end
              end

              if @day&.imported_to_day
                span(class: "text-muted-foreground") do
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
      end

      private

      def full_date
        # Format: "November 19, 2025"
        @date.strftime("%B %-d, %Y")
      end

      def weekday
        # Format: "Wednesday"
        @date.strftime("%A")
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

            # Show "Import from [date]" if latest importable day is available
            if @latest_importable_day
              form(
                action: view_context.import_days_path,
                method: "post",
                class: "w-full",
                data: {
                  controller: "import-loader",
                  action: "submit->import-loader#showLoading"
                }
              ) do
                raw view_context.hidden_field_tag(:authenticity_token, view_context.form_authenticity_token)
                raw view_context.hidden_field_tag(:date, @date.to_s)
                button(
                  type: "submit",
                  class: "w-full text-left px-2 py-1.5 text-sm cursor-pointer hover:bg-accent rounded-sm"
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
end
