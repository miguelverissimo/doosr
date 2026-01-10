module Components
  module Icon
    class X < Base
      private

      def render_icon_path(s)
        s.path(d: "M18 6 6 18")
        s.path(d: "m6 6 12 12")
      end
    end
  end
end
