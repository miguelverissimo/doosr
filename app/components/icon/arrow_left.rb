module Components
  module Icon
    class ArrowLeft < Base
      private

      def render_icon_path(s)
        s.path(d: "M19 12H5")
        s.path(d: "m12 19-7-7 7-7")
      end
    end
  end
end
