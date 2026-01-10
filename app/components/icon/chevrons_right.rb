module Components
  module Icon
    class ChevronsRight < Base
      private

      def render_icon_path(s)
        s.path(d: "m6 17 5-5-5-5")
        s.path(d: "m13 17 5-5-5-5")
      end
    end
  end
end
