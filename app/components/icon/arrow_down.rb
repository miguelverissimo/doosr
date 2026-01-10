module Components
  module Icon
    class ArrowDown < Base
      private

      def render_icon_path(s)
        s.path(d: "M12 5v14")
        s.path(d: "m19 12-7 7-7-7")
      end
    end
  end
end
