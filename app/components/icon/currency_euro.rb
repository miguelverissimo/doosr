module Components
  module Icon
    class CurrencyEuro < Base
      private

      def render_icon_path(s)
        s.path(d: "M4 10h12")
        s.path(d: "M4 14h9")
        s.path(d: "M19 6a7.7 7.7 0 0 0-5.2-2A7.9 7.9 0 0 0 6 12c0 4.4 3.5 8 7.8 8 2 0 3.8-.8 5.2-2")
      end
    end
  end
end
