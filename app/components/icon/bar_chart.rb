# frozen_string_literal: true

module Components
  module Icon
    class BarChart < Base
      private

      def render_icon_path(s)
        s.line(x1: "12", x2: "12", y1: "20", y2: "10")
        s.line(x1: "18", x2: "18", y1: "20", y2: "4")
        s.line(x1: "6", x2: "6", y1: "20", y2: "16")
      end
    end
  end
end
