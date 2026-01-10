module Components
  module Icon
    class Base < ::Components::Base
      def initialize(size: "24", class: nil, stroke_width: "2", **attrs)
        @size = size.to_s
        @icon_class = binding.local_variable_get(:class)
        @stroke_width = stroke_width.to_s
        super(**attrs)
      end

      def view_template
        svg(
          xmlns: "http://www.w3.org/2000/svg",
          width: @size,
          height: @size,
          viewBox: "0 0 24 24",
          fill: "none",
          stroke: "currentColor",
          stroke_width: @stroke_width,
          stroke_linecap: "round",
          stroke_linejoin: "round",
          class: @icon_class,
          **@attrs
        ) do |s|
          render_icon_path(s)
        end
      end

      # Class method to get icon class from symbol name
      def self.for(name)
        class_name = name.to_s.split("_").map(&:capitalize).join
        "::Components::Icon::#{class_name}".constantize
      rescue NameError
        # Return a default/placeholder icon if not found
        ::Components::Icon::Circle
      end

      private

      def render_icon_path(s)
        raise NotImplementedError, "Subclasses must implement this method"
      end
    end
  end
end
