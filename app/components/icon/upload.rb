module Components
  module Icon
    class Upload < Base
      private

      def render_icon_path(s)
        s.path(d: "M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4")
        s.polyline(points: "17 8 12 3 7 8")
        s.line(x1: "12", x2: "12", y1: "3", y2: "15")
      end
    end
  end
end
