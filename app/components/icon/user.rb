module Components
  module Icon
    class User < Base
      private

      def render_icon_path(s)
        s.path(d: "M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2")
        s.circle(cx: "12", cy: "7", r: "4")
      end
    end
  end
end
