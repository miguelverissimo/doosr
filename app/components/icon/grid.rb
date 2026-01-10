module Components
  module Icon
    class Grid < Base
      private

      def render_icon_path(s)
        s.rect(x: "3", y: "3", width: "7", height: "7")
        s.rect(x: "14", y: "3", width: "7", height: "7")
        s.rect(x: "14", y: "14", width: "7", height: "7")
        s.rect(x: "3", y: "14", width: "7", height: "7")
      end
    end
  end
end
