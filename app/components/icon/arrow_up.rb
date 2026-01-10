module Components
  module Icon
    class ArrowUp < Base
      private

      def render_icon_path(s)
        s.path(d: "m5 12 7-7 7 7")
        s.path(d: "M12 19V5")
      end
    end
  end
end
