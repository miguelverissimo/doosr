module Components
  module Icon
    class Edit < Base
      private

      def render_icon_path(s)
        s.path(d: "M12 20h9")
        s.path(d: "M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4L16.5 3.5z")
      end
    end
  end
end
