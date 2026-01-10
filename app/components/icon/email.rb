module Components
  module Icon
    class Email < Base
      private

      def render_icon_path(s)
        s.circle(cx: "12", cy: "12", r: "4")
        s.path(d: "M16 8v5a3 3 0 0 0 6 0v-1a10 10 0 1 0-4 8")
      end
    end
  end
end
