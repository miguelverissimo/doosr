module Views
  module Accounting
    module AccountingItems
      class ListContent < ::Views::Base
        def initialize(user:, **attrs)
          @user = user
          @accounting_items = ::Accounting::AccountingItem.where(user: @user)
          super(**attrs)
        end

        def view_template
          turbo_frame_tag "accounting_items_content" do
            if @accounting_items.empty?
              div(class: "flex h-full flex-col items-center justify-center") do
                p(class: "text-sm text-gray-500") { "No accounting items found" }
              end
            else
              @accounting_items.each do |accounting_item|
                div(id: "accounting_item_#{accounting_item.id}_div", class: "mt-2") do
                  render ::Views::Accounting::AccountingItems::AccountingItemRow.new(accounting_item: accounting_item)
                end
              end
            end
          end
        end
      end
    end
  end
end
