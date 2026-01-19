module Components
  module Icon
    class ArrowUpDown < Base
      private

      def render_icon_path(s)
        s.path(d: "m21 16-4 4-4-4")
        s.path(d: "M17 20V4")
        s.path(d: "m3 8 4-4 4 4")
        s.path(d: "M7 4v16")
      end
    end
  end
end
