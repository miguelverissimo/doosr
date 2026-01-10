module Components
  module Icon
    class BookOpen < Base
      private

      def render_icon_path(s)
        s.path(d: "M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z")
        s.path(d: "M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z")
      end
    end
  end
end
