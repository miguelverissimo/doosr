# frozen_string_literal: true

module Views
  module Days
    class Show < Views::Base
      def initialize(day:, date:, is_today:)
        @day = day
        @date = date
        @is_today = is_today
      end

      def view_template
        div(class: "flex h-full flex-col") do
          # Header
          header(class: "mb-6") do
            div(class: "flex items-center justify-between") do
              div do
                h1(class: "text-2xl font-semibold") do
                  @date.strftime("%B %-d, %Y")
                end
                p(class: "text-sm text-muted-foreground mt-0.5") do
                  @date.strftime("%A")
                end
              end

              # Action buttons
              div(class: "flex items-center gap-3") do
                # Status text
                span(class: "text-sm text-muted-foreground") do
                  if @day.closed?
                    "closed"
                  elsif @day.descendant&.active_items&.empty? && @day.descendant&.inactive_items&.empty?
                    "empty"
                  else
                    # Show item count here later
                    ""
                  end
                end

                # Menu button
                Button(variant: :ghost, icon: true, size: :sm) do
                  svg(
                    xmlns: "http://www.w3.org/2000/svg",
                    class: "h-5 w-5",
                    viewBox: "0 0 24 24",
                    fill: "none",
                    stroke: "currentColor",
                    stroke_width: "2"
                  ) do |s|
                    s.circle(cx: "12", cy: "12", r: "1")
                    s.circle(cx: "12", cy: "5", r: "1")
                    s.circle(cx: "12", cy: "19", r: "1")
                  end
                end
              end
            end
          end

          # Content - always show the same interface
          div(class: "flex-1") do
            render_day_content
          end
        end
      end

      private

      def render_day_content
        div(class: "space-y-4") do
          # Status bar (purple card at top)
          div(class: "rounded-lg bg-slate-800/50 p-4 flex items-center justify-center") do
            # Placeholder for status/stats
            svg(
              xmlns: "http://www.w3.org/2000/svg",
              class: "h-5 w-5 text-muted-foreground",
              viewBox: "0 0 24 24",
              fill: "none",
              stroke: "currentColor",
              stroke_width: "2"
            ) do |s|
              s.path(d: "M12 8v4l3 3")
              s.circle(cx: "12", cy: "12", r: "10")
            end
          end

          # Add item input
          div(class: "flex items-center gap-2") do
            Input(
              type: "text",
              placeholder: "Add an item...",
              class: "flex-1"
            )

            Button(variant: :ghost, icon: true, class: "shrink-0") do
              svg(
                xmlns: "http://www.w3.org/2000/svg",
                class: "h-5 w-5",
                viewBox: "0 0 24 24",
                fill: "none",
                stroke: "currentColor",
                stroke_width: "2"
              ) do |s|
                s.line(x1: "12", y1: "5", x2: "12", y2: "19")
                s.line(x1: "5", y1: "12", x2: "19", y2: "12")
              end
            end

            Button(variant: :ghost, icon: true, size: :sm, class: "shrink-0") do
              svg(
                xmlns: "http://www.w3.org/2000/svg",
                class: "h-5 w-5",
                viewBox: "0 0 24 24",
                fill: "none",
                stroke: "currentColor",
                stroke_width: "2"
              ) do |s|
                s.polyline(points: "9 11 12 14 22 4")
                s.path(d: "M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11")
              end
            end

            Button(variant: :ghost, icon: true, size: :sm, class: "shrink-0") do
              svg(
                xmlns: "http://www.w3.org/2000/svg",
                class: "h-5 w-5",
                viewBox: "0 0 24 24",
                fill: "none",
                stroke: "currentColor",
                stroke_width: "2"
              ) do |s|
                s.path(d: "M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4")
                s.polyline(points: "7 10 12 15 17 10")
                s.line(x1: "12", y1: "15", x2: "12", y2: "3")
              end
            end

            Button(variant: :ghost, icon: true, size: :sm, class: "shrink-0") do
              svg(
                xmlns: "http://www.w3.org/2000/svg",
                class: "h-5 w-5",
                viewBox: "0 0 24 24",
                fill: "none",
                stroke: "currentColor",
                stroke_width: "2"
              ) do |s|
                s.rect(x: "3", y: "3", width: "18", height: "18", rx: "2", ry: "2")
                s.line(x1: "9", y1: "3", x2: "9", y2: "21")
              end
            end
          end
        end
      end
    end
  end
end
