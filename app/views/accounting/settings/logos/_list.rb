module Views
  module Accounting
    module Settings
      module Logos
        class List < ::Views::Base
          def initialize(user:)
            @user = user
          end

          def view_template
            div(id: "accounting_logos_list") do
              turbo_frame_tag "accounting_logos_content", data: { lazy_tab_target: "frame", src: settings_logos_path } do
                render ::Components::Shared::LoadingSpinner.new(message: "Loading logos...")
              end
            end
          end
        end
      end
    end
  end
end
