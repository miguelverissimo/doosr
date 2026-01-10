module Components
  module Icon
    class Move < Base
      private

      def render_icon_path(s)
        s.polyline(points: "5 9 2 12 5 15")
        s.polyline(points: "9 5 12 2 15 5")
        s.polyline(points: "15 19 12 22 9 19")
        s.polyline(points: "19 9 22 12 19 15")
        s.line(x1: "2", x2: "22", y1: "12", y2: "12")
        s.line(x1: "12", x2: "12", y1: "2", y2: "22")
      end
    end
  end
end
