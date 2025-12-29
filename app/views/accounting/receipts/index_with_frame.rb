module Views
  module Accounting
    module Receipts
      class IndexWithFrame < ::Views::Base
        def initialize(user:)
          @user = user
        end

        def view_template
          turbo_frame_tag "receipts_index_content" do
            render ::Views::Accounting::Receipts::Index.new(user: @user)
          end
        end
      end
    end
  end
end
