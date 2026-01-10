module Components
  module Icon
    class Accounting < Base
      private

      def render_icon_path(s)
        s.circle(cx: "12", cy: "12", r: "10")
        s.path(d: "M16 8h-6a2 2 0 1 0 0 4h4a2 2 0 1 1 0 4H8")
        s.path(d: "M12 18V6")
      end
    end
  end
end
