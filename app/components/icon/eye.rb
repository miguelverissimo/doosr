module Components
  module Icon
    class Eye < Base
      private

      def render_icon_path(s)
        s.path(d: "M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z")
        s.circle(cx: "12", cy: "12", r: "3")
      end
    end
  end
end
