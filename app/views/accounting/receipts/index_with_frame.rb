module Views
  module Accounting
    module Receipts
      class IndexWithFrame < ::Views::Base
        def initialize(user:, page: 1, search_query: nil, invoice_number: nil, date_from: nil, date_to: nil)
          @user = user
          @page = page
          @search_query = search_query
          @invoice_number = invoice_number
          @date_from = date_from
          @date_to = date_to
        end

        def view_template
          turbo_frame_tag "receipts_index_content" do
            render ::Views::Accounting::Receipts::Index.new(
              user: @user,
              page: @page,
              search_query: @search_query,
              invoice_number: @invoice_number,
              date_from: @date_from,
              date_to: @date_to
            )
          end
        end
      end
    end
  end
end
