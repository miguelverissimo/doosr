module Components
  module Icon
    class CheckCircle < Base
      private

      def render_icon_path(s)
        s.path(d: "M22 11.08V12a10 10 0 1 1-5.93-9.14")
        s.polyline(points: "22 4 12 14.01 9 11.01")
      end
    end
  end
end
