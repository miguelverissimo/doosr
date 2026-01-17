module Components
  module Icon
    class BellRing < Base
      private

      def render_icon_path(s)
        s.path(d: "M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9")
        s.path(d: "M10.3 21a1.94 1.94 0 0 0 3.4 0")
        s.path(d: "M4 2C2.8 3.7 2 5.7 2 8")
        s.path(d: "M22 8c0-2.3-.8-4.3-2-6")
      end
    end
  end
end
