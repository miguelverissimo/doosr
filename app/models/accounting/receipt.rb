module Accounting
  class Receipt < ApplicationRecord
    include MoneyPresentable

    belongs_to :user
    belongs_to :invoice, optional: true, class_name: "Accounting::Invoice"
    has_many :items, class_name: "Accounting::ReceiptReceiptItem", dependent: :destroy
    has_many :receipt_items, through: :items, source: :receipt_item, class_name: "Accounting::ReceiptItem"

    enum :kind, {
      receipt: :receipt,
      invoice_receipt: :invoice_receipt,
    }, default: :receipt, validate: true

    validates :kind, presence: true
    validates :kind, inclusion: { in: kinds.keys }

    validates :reference, presence: true
    validates :issue_date, presence: true
    validates :payment_date, presence: true
    validates :value, presence: true

    money_attribute :value
  end
end