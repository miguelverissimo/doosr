module Views
  module Accounting
    module Customers
      class List < ::Views::Base
        def initialize(user:)
          @user = user
        end

        def view_template
          # Container for Turbo Stream updates
          div(id: "customers_list") do
            # Turbo Frame for lazy loading - src will be added by Stimulus controller
            turbo_frame_tag "customers_content", data: { lazy_tab_target: "frame", src: customers_path } do
              render ::Components::Shared::LoadingSpinner.new(message: "Loading customers...")
            end
          end
        end
      end
    end
  end
end