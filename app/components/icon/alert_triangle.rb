# frozen_string_literal: true

module Components
  module Icon
    class AlertTriangle < Base
      private

      def render_icon_path(s)
        s.path(d: "m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z")
        s.path(d: "M12 9v4")
        s.path(d: "M12 17h.01")
      end
    end
  end
end
