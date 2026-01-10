module Components
  module Icon
    class Check < Base
      private

      def render_icon_path(s)
        s.polyline(points: "20 6 9 17 4 12")
      end
    end
  end
end
