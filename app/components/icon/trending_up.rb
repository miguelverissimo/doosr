# frozen_string_literal: true

module Components
  module Icon
    class TrendingUp < Base
      private

      def render_icon_path(s)
        s.polyline(points: "22 7 13.5 15.5 8.5 10.5 2 17")
        s.polyline(points: "16 7 22 7 22 13")
      end
    end
  end
end
