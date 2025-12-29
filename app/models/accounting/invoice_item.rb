module Accounting
  class InvoiceItem < ApplicationRecord
    include MoneyPresentable

    belongs_to :user
    belongs_to :item, class_name: "Accounting::AccountingItem"
    belongs_to :invoice, class_name: "Accounting::Invoice"
    belongs_to :tax_bracket, class_name: "Accounting::TaxBracket"

    validates :description, presence: true
    validates :quantity, presence: true
    validates :unit, presence: true
    validates :unit_price, presence: true
    validates :subtotal, presence: true
    validates :discount_rate, presence: true
    validates :discount_amount, presence: true
    validates :tax_bracket, presence: true
    validates :tax_rate, presence: true
    validates :tax_amount, presence: true
    validates :amount, presence: true

    money_attribute :unit_price, :subtotal, :discount_amount, :tax_amount, :amount

    after_commit :recalculate_invoice_totals, on: [ :create, :update, :destroy ]

    private

    def recalculate_invoice_totals
      # When the parent invoice is being destroyed, this callback can still run
      # for the associated items. In that case, skip recalculation to avoid
      # trying to update a destroyed record.
      return unless invoice && invoice.persisted? && !invoice.destroyed?

      invoice.recalculate_totals!
    end
  end
end
