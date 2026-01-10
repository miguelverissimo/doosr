module Components
  module Icon
    class PaymentDate < Base
      private

      def render_icon_path(s)
        s.path(d: "M8 2v4")
        s.path(d: "M16 2v4")
        s.path(d: "M21 14V6a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h8")
        s.path(d: "M3 10h18")
        s.path(d: "m16 20 2 2 4-4")
      end
    end
  end
end
