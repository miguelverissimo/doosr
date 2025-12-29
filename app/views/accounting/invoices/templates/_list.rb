module Views
  module Accounting
    module Invoices
      module Templates
        class List < ::Views::Base
          def initialize(user:)
            @user = user
          end

          def view_template
            # Container for Turbo Stream updates
            div(id: "invoice_templates_list") do
              turbo_frame_tag "invoice_templates_content", data: { lazy_tab_target: "frame", src: view_context.invoice_templates_path } do
                render ::Components::Shared::LoadingSpinner.new(message: "Loading invoice templates...")
              end
            end
          end
        end
      end
    end
  end
end