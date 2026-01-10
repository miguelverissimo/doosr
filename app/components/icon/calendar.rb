module Components
  module Icon
    class Calendar < Base
      private

      def render_icon_path(s)
        s.path(d: "M8 2v4")
        s.path(d: "M16 2v4")
        s.rect(width: "18", height: "18", x: "3", y: "4", rx: "2")
        s.path(d: "M3 10h18")
      end
    end
  end
end
