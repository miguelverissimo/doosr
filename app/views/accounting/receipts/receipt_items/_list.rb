module Views
  module Accounting
    module Receipts
      module ReceiptItems
        class List < ::Views::Base
          def initialize(user:)
            @user = user
          end

          def view_template
            # Container for Turbo Stream updates
            div(id: "receipt_items_list") do
              turbo_frame_tag "receipt_items_content", data: { lazy_tab_target: "frame", src: view_context.receipt_items_path } do
                render ::Components::Shared::LoadingSpinner.new(message: "Loading receipt items...")
              end
            end
          end
        end
      end
    end
  end
end