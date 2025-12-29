# frozen_string_literal: true

module RubyUI
  class ThemeToggle < Base
    def initialize(**attrs)
      @light_mode_block = nil
      @dark_mode_block = nil
      super(**attrs)
    end

    def view_template(&block)
      div(**attrs) do
        if block_given?
          builder = ThemeToggleBuilder.new(self)
          yield(builder)
          @light_mode_block = builder.light_mode_block
          @dark_mode_block = builder.dark_mode_block
        end
        render_light_mode
        render_dark_mode
      end
    end

    def SetLightMode(&block)
      @light_mode_block = block
    end

    def SetDarkMode(&block)
      @dark_mode_block = block
    end

    private

    def render_light_mode
      return unless @light_mode_block

      div(class: "hidden dark:block") do
        div(data: { action: "click->ruby-ui--theme-toggle#toggle" }) do
          instance_eval(&@light_mode_block)
        end
      end
    end

    def render_dark_mode
      return unless @dark_mode_block

      div(class: "block dark:hidden") do
        div(data: { action: "click->ruby-ui--theme-toggle#toggle" }) do
          instance_eval(&@dark_mode_block)
        end
      end
    end

    def default_attrs
      {
        data: {
          controller: "ruby-ui--theme-toggle"
        }
      }
    end

    class ThemeToggleBuilder
      attr_reader :light_mode_block, :dark_mode_block

      def initialize(toggle)
        @toggle = toggle
        @light_mode_block = nil
        @dark_mode_block = nil
      end

      def SetLightMode(&block)
        @light_mode_block = block
      end

      def SetDarkMode(&block)
        @dark_mode_block = block
      end
    end
  end
end
