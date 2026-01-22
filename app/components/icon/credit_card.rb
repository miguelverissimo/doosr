module Components
  module Icon
    class CreditCard < Base
      private

      def render_icon_path(s)
        s.rect(width: "20", height: "14", x: "2", y: "5", rx: "2")
        s.path(d: "M2 10h20")
      end
    end
  end
end
