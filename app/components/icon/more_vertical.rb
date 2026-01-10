module Components
  module Icon
    class MoreVertical < Base
      private

      def render_icon_path(s)
        s.circle(cx: "12", cy: "12", r: "1")
        s.circle(cx: "12", cy: "5", r: "1")
        s.circle(cx: "12", cy: "19", r: "1")
      end
    end
  end
end
