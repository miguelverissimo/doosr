module Components
  module Icon
    class ChevronLeft < Base
      private

      def render_icon_path(s)
        s.path(d: "m15 18-6-6 6-6")
      end
    end
  end
end
