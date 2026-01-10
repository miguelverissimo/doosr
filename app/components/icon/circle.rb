module Components
  module Icon
    class Circle < Base
      private

      def render_icon_path(s)
        s.circle(cx: "12", cy: "12", r: "10")
      end
    end
  end
end
