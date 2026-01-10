module Components
  module Icon
    class ArrowRight < Base
      private

      def render_icon_path(s)
        s.path(d: "M5 12h14")
        s.path(d: "m12 5 7 7-7 7")
      end
    end
  end
end
