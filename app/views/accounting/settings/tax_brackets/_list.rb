module Views
  module Accounting
    module Settings
      module TaxBrackets
        class List < ::Views::Base
          def initialize(user:)
            @user = user
          end

          def view_template
            div(id: "tax_brackets_list") do
              turbo_frame_tag "tax_brackets_content", data: { lazy_tab_target: "frame", src: settings_tax_brackets_path } do
                render ::Components::Shared::LoadingSpinner.new(message: "Loading tax brackets...")
              end
            end
          end
        end
      end
    end
  end
end
