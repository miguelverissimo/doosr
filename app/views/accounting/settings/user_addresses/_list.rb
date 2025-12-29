module Views
  module Accounting
    module Settings
      module UserAddresses
        class List < ::Views::Base
          def initialize(user:)
            @user = user
          end

          def view_template
            div(id: "addresses_list") do
              turbo_frame_tag "addresses_content", data: { lazy_tab_target: "frame", src: settings_addresses_path } do
                render ::Components::Shared::LoadingSpinner.new(message: "Loading addresses...")
              end
            end
          end
        end
      end
    end
  end
end