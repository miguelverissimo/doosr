module Components
  module Icon
    class ChevronRight < Base
      private

      def render_icon_path(s)
        s.path(d: "m9 18 6-6-6-6")
      end
    end
  end
end
