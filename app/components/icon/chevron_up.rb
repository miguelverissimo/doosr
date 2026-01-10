module Components
  module Icon
    class ChevronUp < Base
      private

      def render_icon_path(s)
        s.path(d: "m18 15-6-6-6 6")
      end
    end
  end
end
