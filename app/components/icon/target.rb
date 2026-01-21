# frozen_string_literal: true

module Components
  module Icon
    class Target < Base
      private

      def render_icon_path(s)
        s.circle(cx: "12", cy: "12", r: "10")
        s.circle(cx: "12", cy: "12", r: "6")
        s.circle(cx: "12", cy: "12", r: "2")
      end
    end
  end
end
