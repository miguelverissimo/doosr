module Components
  module Icon
    class Clock < Base
      private

      def render_icon_path(s)
        s.path(d: "M12 6v6l4 2")
        s.circle(cx: "12", cy: "12", r: "10")
      end
    end
  end
end
