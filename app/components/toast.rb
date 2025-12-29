# frozen_string_literal: true

class ::Components::Toast < ::Components::Base
  def initialize(position: "top-center", layout: "default", gap: 14, auto_dismiss_duration: 4000, limit: 3)
    @position = position
    @layout = layout
    @gap = gap
    @auto_dismiss_duration = auto_dismiss_duration
    @limit = limit
  end

  def view_template
    div(
      data: {
        controller: "ruby-ui--toast",
        ruby_ui__toast_position_value: @position,
        ruby_ui__toast_layout_value: @layout,
        ruby_ui__toast_gap_value: @gap,
        ruby_ui__toast_auto_dismiss_duration_value: @auto_dismiss_duration,
        ruby_ui__toast_limit_value: @limit,
        action: "mouseenter->ruby-ui--toast#handleMouseEnter mouseleave->ruby-ui--toast#handleMouseLeave"
      }
    ) do
      ul(
        data: { ruby_ui__toast_target: "container" },
        class: "fixed block w-full z-[100] flex flex-col gap-0 list-none p-0 m-0 pointer-events-none max-w-[300px] sm:max-w-xs"
      )
    end
  end
end

