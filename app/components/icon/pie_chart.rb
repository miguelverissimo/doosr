# frozen_string_literal: true

module Components
  module Icon
    class PieChart < Base
      private

      def render_icon_path(s)
        s.path(d: "M21.21 15.89A10 10 0 1 1 8 2.83")
        s.path(d: "M22 12A10 10 0 0 0 12 2v10z")
      end
    end
  end
end
