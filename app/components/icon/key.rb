module Components
  module Icon
    class Key < Base
      private

      def render_icon_path(s)
        s.circle(cx: "7.5", cy: "15.5", r: "5.5")
        s.path(d: "m21 2-9.6 9.6")
        s.path(d: "m15.5 7.5 3 3L22 7l-3-3")
      end
    end
  end
end
