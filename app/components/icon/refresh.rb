module Components
  module Icon
    class Refresh < Base
      private

      def render_icon_path(s)
        s.path(d: "M21 12a9 9 0 0 0-9-9 9.75 9.75 0 0 0-6.74 2.74L3 8")
        s.path(d: "M3 3v5h5")
        s.path(d: "M3 12a9 9 0 0 0 9 9 9.75 9.75 0 0 0 6.74-2.74L21 16")
        s.path(d: "M16 16h5v5")
      end
    end
  end
end
