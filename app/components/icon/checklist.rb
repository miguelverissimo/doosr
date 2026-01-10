module Components
  module Icon
    class Checklist < Base
      private

      def render_icon_path(s)
        s.path(d: "M13 5h8")
        s.path(d: "M13 12h8")
        s.path(d: "M13 19h8")
        s.path(d: "m3 17 2 2 4-4")
        s.rect(x: "3", y: "4", width: "6", height: "6", rx: "1")
      end
    end
  end
end
