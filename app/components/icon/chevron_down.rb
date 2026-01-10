module Components
  module Icon
    class ChevronDown < Base
      private

      def render_icon_path(s)
        s.path(d: "m6 9 6 6 6-6")
      end
    end
  end
end
