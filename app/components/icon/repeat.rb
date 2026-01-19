# frozen_string_literal: true

module Components
  module Icon
    class Repeat < Base
      private

      def render_icon_path(s)
        s.path(d: "m17 2 4 4-4 4")
        s.path(d: "M3 11v-1a4 4 0 0 1 4-4h14")
        s.path(d: "m7 22-4-4 4-4")
        s.path(d: "M21 13v1a4 4 0 0 1-4 4H3")
      end
    end
  end
end
