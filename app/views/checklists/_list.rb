module Views
  module Checklists
    class List < ::Views::Base
      def initialize(user:)
        @user = user
      end

      def view_template
        div(id: "checklists_list") do
          render ::Views::Checklists::ListContent.new(user: @user)
        end
      end
    end
  end
end
