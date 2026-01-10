module Components
  module Icon
    class GitBranch < Base
      private

      def render_icon_path(s)
        s.line(x1: "6", x2: "6", y1: "3", y2: "15")
        s.circle(cx: "18", cy: "6", r: "3")
        s.circle(cx: "6", cy: "18", r: "3")
        s.path(d: "M18 9a9 9 0 0 1-9 9")
      end
    end
  end
end
