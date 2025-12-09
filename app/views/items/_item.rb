# frozen_string_literal: true

module Views
  module Items
    class Item < Views::Base
      def initialize(item:, day: nil)
        @item = item
        @day = day
      end

      def view_template
        div(
          id: "item_#{@item.id}",
          class: item_classes,
          data: {
            controller: "item",
            item_id_value: @item.id,
            item_day_id_value: @day&.id,
            item_type_value: @item.item_type,
            action: "click->item#openSheet",
            day_move_target: "item"
          }
        ) do
          # Checkbox for completable items
          if @item.completable?
            render_checkbox
          elsif @item.section?
            render_section_icon
          end

          # Item title
          div(class: "flex-1 min-w-0") do
            if @item.section?
              h3(class: "font-semibold text-xs truncate") { @item.title }
            else
              p(class: "text-xs truncate #{@item.done? ? 'line-through text-muted-foreground' : ''}") { @item.title }
            end
          end

          # Actions menu (hidden, shown on hover)
          div(class: "opacity-0 group-hover:opacity-100 transition-opacity flex items-center gap-1") do
            Button(variant: :ghost, icon: true, size: :sm, class: "h-7 w-7") do
              render_icon(:more_vertical)
            end
          end
        end
      end

      private

      def item_classes
        case @item.item_type.to_sym
        when :completable
          "group flex items-center gap-2 rounded-lg border bg-card p-2.5 hover:bg-accent/50 transition-colors cursor-pointer"
        when :section
          "flex w-full cursor-pointer items-center gap-2 rounded-md bg-muted p-3 text-left transition-colors hover:bg-muted/85"
        else
          "flex w-full cursor-pointer items-center gap-2 rounded-md border bg-card p-3 text-left transition-colors hover:bg-muted/50"
        end
      end

      def render_checkbox
        form(
          action: item_path(@item),
          method: "post",
          data: {
            turbo: "true",
            action: "change->item#toggle"
          },
          class: "shrink-0"
        ) do
          csrf_token_field
          input(type: "hidden", name: "_method", value: "patch")
          input(type: "hidden", name: "item[state]", value: @item.done? ? "todo" : "done")

          input(
            type: "checkbox",
            checked: @item.done?,
            class: "h-3.5 w-3.5 rounded border-gray-300 text-primary focus:ring-2 focus:ring-primary focus:ring-offset-2 cursor-pointer",
            data: { action: "change->item#toggle" }
          )
        end
      end

      def render_section_icon
        div(class: "flex h-3.5 w-3.5 items-center justify-center shrink-0") do
          render_icon(:hash)
        end
      end

      def render_icon(name)
        case name
        when :more_vertical
          svg(
            xmlns: "http://www.w3.org/2000/svg",
            width: "14",
            height: "14",
            viewBox: "0 0 24 24",
            fill: "none",
            stroke: "currentColor",
            stroke_width: "2",
            stroke_linecap: "round",
            stroke_linejoin: "round",
            class: "shrink-0"
          ) do |s|
            s.circle(cx: "12", cy: "12", r: "1")
            s.circle(cx: "12", cy: "5", r: "1")
            s.circle(cx: "12", cy: "19", r: "1")
          end
        when :hash
          svg(
            xmlns: "http://www.w3.org/2000/svg",
            width: "14",
            height: "14",
            viewBox: "0 0 24 24",
            fill: "none",
            stroke: "currentColor",
            stroke_width: "2",
            stroke_linecap: "round",
            stroke_linejoin: "round",
            class: "text-muted-foreground"
          ) do |s|
            s.line(x1: "4", x2: "20", y1: "9", y2: "9")
            s.line(x1: "4", x2: "20", y1: "15", y2: "15")
            s.line(x1: "10", x2: "8", y1: "3", y2: "21")
            s.line(x1: "16", x2: "14", y1: "3", y2: "21")
          end
        end
      end
    end
  end
end
