# frozen_string_literal: true

module RubyUI
  class ResponsiveTabsList < Base
    def initialize(tabs:, current_value:, **attrs)
      @tabs = tabs # Array of {value: "invoices", label: "Invoices"}
      @current_value = current_value
      super(**attrs)
    end

    def view_template
      # Desktop: Show regular tabs (hidden on mobile, visible on md and up)
      div(class: "max-md:hidden") do
        TabsList(**attrs) do
          @tabs.each do |tab|
            TabsTrigger(value: tab[:value]) { tab[:label] }
          end
        end
      end

      # Mobile: Show dropdown menu (visible on mobile, hidden on md and up)
      div(class: "md:hidden") do
        render_mobile_dropdown
      end
    end

    private

    def render_mobile_dropdown
      current_tab = @tabs.find { |t| t[:value] == @current_value } || @tabs.first

      render DropdownMenu.new do
        render DropdownMenuTrigger.new do
          Button(variant: :outline, class: "w-full justify-between") do
            span { current_tab[:label] }
            render ::Components::Icon::ArrowDown.new(size: "16", class: "ml-2 h-4 w-4")
          end
        end

        render DropdownMenuContent.new do
          @tabs.each do |tab|
            button(
              type: :button,
              class: "relative flex w-full cursor-pointer select-none items-center rounded-sm px-2 py-1.5 text-sm outline-none transition-colors hover:bg-accent hover:text-accent-foreground focus:bg-accent focus:text-accent-foreground #{tab[:value] == @current_value ? 'bg-accent text-accent-foreground' : ''}",
              data: {
                ruby_ui__tabs_target: "trigger",
                action: "click->ruby-ui--tabs#show click->ruby-ui--dropdown-menu#close",
                value: tab[:value]
              }
            ) { tab[:label] }
          end
        end
      end
    end

    def default_attrs
      {}
    end
  end
end
