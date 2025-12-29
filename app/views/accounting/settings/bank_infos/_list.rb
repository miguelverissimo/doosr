module Views
  module Accounting
    module Settings
      module BankInfos
        class List < ::Views::Base
          def initialize(user:)
            @user = user
          end

          def view_template
            div(id: "bank_infos_list") do
              turbo_frame_tag "bank_infos_content", data: { lazy_tab_target: "frame", src: settings_bank_infos_path } do
                render ::Components::Shared::LoadingSpinner.new(message: "Loading bank infos...")
              end
            end
          end
        end
      end
    end
  end
end
