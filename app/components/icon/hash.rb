module Components
  module Icon
    class Hash < Base
      private

      def render_icon_path(s)
        s.line(x1: "4", x2: "20", y1: "9", y2: "9")
        s.line(x1: "4", x2: "20", y1: "15", y2: "15")
        s.line(x1: "10", x2: "8", y1: "3", y2: "21")
        s.line(x1: "16", x2: "14", y1: "3", y2: "21")
      end
    end
  end
end
