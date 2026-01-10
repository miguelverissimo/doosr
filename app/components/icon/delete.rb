module Components
  module Icon
    class Delete < Base
      private

      def render_icon_path(s)
        s.path(d: "M3 6h18")
        s.path(d: "M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2")
      end
    end
  end
end
