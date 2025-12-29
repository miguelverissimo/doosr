module Views
  module Accounting
    module AccountingItems
      class List < ::Views::Base
        def initialize(user:)
          @user = user
        end

        def view_template
          div(id: "accounting_items_list") do
            turbo_frame_tag "accounting_items_content", data: { lazy_tab_target: "frame", src: accounting_items_path } do
              render ::Components::Shared::LoadingSpinner.new(message: "Loading accounting items...")
            end
          end
        end
      end
    end
  end
end
