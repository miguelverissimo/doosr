module Views
  module Accounting
    module Receipts
      class List < ::Views::Base
        def initialize(user:)
          @user = user
        end

        def view_template
          # Container for Turbo Stream updates
          div(id: "receipts_list") do
            turbo_frame_tag "receipts_content", data: { lazy_tab_target: "frame", src: view_context.receipts_path } do
              render ::Components::Shared::LoadingSpinner.new(message: "Loading receipts...")
            end
          end
        end
      end
    end
  end
end