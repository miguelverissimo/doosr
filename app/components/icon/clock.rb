module Components
  module Icon
    class Clock < Base
      private

      def render_icon_path(s)
        s.circle(cx: "12", cy: "12", r: "10")
        s.polyline(points: "12 6 12 12 16 14")
      end
    end
  end
end
