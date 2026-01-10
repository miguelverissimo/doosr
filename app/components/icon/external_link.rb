module Components
  module Icon
    class ExternalLink < Base
      private

      def render_icon_path(s)
        s.path(d: "M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6")
        s.polyline(points: "15 3 21 3 21 9")
        s.line(x1: "10", x2: "21", y1: "14", y2: "3")
      end
    end
  end
end
