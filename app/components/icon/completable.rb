module Components
  module Icon
    class Completable < Base
      private

      def render_icon_path(s)
        s.path(d: "M21 10.656V19a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h12.344")
        s.path(d: "m9 11 3 3L22 4")
      end
    end
  end
end
