module Components
  module Icon
    class Section < Base
      private

      def render_icon_path(s)
        s.path(d: "M8 5h13")
        s.path(d: "M13 12h8")
        s.path(d: "M13 19h8")
        s.path(d: "M3 10a2 2 0 0 0 2 2h3")
        s.path(d: "M3 5v12a2 2 0 0 0 2 2h3")
      end
    end
  end
end
