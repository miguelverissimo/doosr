module Components
  module Icon
    class Trash < Base
      private

      def render_icon_path(s)
        s.path(d: "M3 6h18")
        s.path(d: "M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2")
        s.line(x1: "10", x2: "10", y1: "11", y2: "17")
        s.line(x1: "14", x2: "14", y1: "11", y2: "17")
      end
    end
  end
end
