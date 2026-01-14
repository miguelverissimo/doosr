module Components
  module Icon
    class LockOpen < Base
      private

      def render_icon_path(s)
        s.rect(width: "18", height: "11", x: "3", y: "11", rx: "2", ry: "2")
        s.path(d: "M7 11V7a5 5 0 0 1 9.9-1")
      end
    end
  end
end
