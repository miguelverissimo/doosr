module Components
  module Icon
    class NoCurrencyConversion < Base
      private

      def render_icon_path(s)
        s.path(d: "M13 18H4a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5")
        s.path(d: "m17 17 5 5")
        s.path(d: "M18 12h.01")
        s.path(d: "m22 17-5 5")
        s.path(d: "M6 12h.01")
        s.circle(cx: "12", cy: "12", r: "2")
      end
    end
  end
end
