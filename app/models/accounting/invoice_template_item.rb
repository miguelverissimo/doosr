module Accounting
  class InvoiceTemplateItem < ApplicationRecord
    belongs_to :invoice_template, class_name: "Accounting::InvoiceTemplate"
    belongs_to :user
    belongs_to :item, class_name: "Accounting::AccountingItem"
    belongs_to :tax_bracket, class_name: "Accounting::TaxBracket"

    validates :invoice_template, presence: true
    validates :user, presence: true
    validates :item, presence: true
    validates :tax_bracket, presence: true
    validates :quantity, presence: true
    validates :unit, presence: true
    validates :discount_rate, presence: true
  end
end
