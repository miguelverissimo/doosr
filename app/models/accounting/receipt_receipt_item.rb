module Accounting
  class ReceiptReceiptItem < ApplicationRecord
    include MoneyPresentable

    belongs_to :user
    belongs_to :receipt, class_name: "Accounting::Receipt"
    belongs_to :receipt_item, class_name: "Accounting::ReceiptItem"

    validates :quantity, presence: true
    validates :gross_value, presence: true
    validates :tax_percentage, presence: true
    validates :value_with_tax, presence: true

    money_attribute :gross_value, :value_with_tax
  end
end
