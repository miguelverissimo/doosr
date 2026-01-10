module Components
  module Icon
    class Draft < Base
      private

      def render_icon_path(s)
        s.rect(x: "2", y: "6", width: "20", height: "8", rx: "1")
        s.path(d: "M17 14v7")
        s.path(d: "M7 14v7")
        s.path(d: "M17 3v3")
        s.path(d: "M7 3v3")
        s.path(d: "M10 14 2.3 6.3")
        s.path(d: "m14 6 7.7 7.7")
        s.path(d: "m8 6 8 8")
      end
    end
  end
end
