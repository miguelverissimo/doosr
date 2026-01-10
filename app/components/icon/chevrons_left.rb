module Components
  module Icon
    class ChevronsLeft < Base
      private

      def render_icon_path(s)
        s.path(d: "m11 17-5-5 5-5")
        s.path(d: "m18 17-5-5 5-5")
      end
    end
  end
end
