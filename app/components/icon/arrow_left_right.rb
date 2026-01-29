# frozen_string_literal: true

module Components
  module Icon
    class ArrowLeftRight < Base
      private

      def render_icon_path(s)
        s.path(d: "M8 3 4 7l4 4")
        s.path(d: "M4 7h16")
        s.path(d: "m16 21 4-4-4-4")
        s.path(d: "M20 17H4")
      end
    end
  end
end
