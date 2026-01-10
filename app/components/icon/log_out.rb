module Components
  module Icon
    class LogOut < Base
      private

      def render_icon_path(s)
        s.path(d: "M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4")
        s.polyline(points: "16 17 21 12 16 7")
        s.line(x1: "21", x2: "9", y1: "12", y2: "12")
      end
    end
  end
end
