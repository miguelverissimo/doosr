module Views
  module Accounting
    module Settings
      module TaxBrackets
        class List < Views::Base
          def initialize(user:)
            @user = user
          end

          def view_template
            # Use turbo-frame element for Turbo Stream updates
            # Render the turbo-frame using Rails helper to ensure it's a proper HTML element
            content_html = view_context.capture do
              render Views::Accounting::Settings::TaxBrackets::ListContent.new(user: @user)
            end
            turbo_frame_html = view_context.content_tag("turbo-frame", content_html.html_safe, id: "tax_brackets_list")
            raw turbo_frame_html
          end
        end
      end
    end
  end
end