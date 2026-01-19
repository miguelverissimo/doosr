module Components
  module Icon
    class Banking < Base
      private

      def render_icon_path(s)
        s.path(d: "M3 21h18")
        s.path(d: "M3 10h18")
        s.path(d: "M5 6l7-3 7 3")
        s.path(d: "M4 10v11")
        s.path(d: "M20 10v11")
        s.path(d: "M8 14v3")
        s.path(d: "M12 14v3")
        s.path(d: "M16 14v3")
      end
    end
  end
end
