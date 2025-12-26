module Accounting
  class ReceiptItem < ApplicationRecord
    include MoneyPresentable

    belongs_to :user
    belongs_to :tax_bracket, class_name: "Accounting::TaxBracket"

    enum :unit, {
      hour: :hour,
      unit: :unit,
    }, default: :hour, validate: true

    enum :kind, {
      product: :product,
      service: :service,
      tool: :tool,
      goods: :goods,
      equipment: :equipment,
      other: :other
    }, default: :service, validate: true

    validates :reference, presence: true
    validates :description, presence: true
    validates :unit, presence: true
    validates :gross_unit_price, presence: true
    validates :tax_bracket, presence: true
    validates :exemption_motive, presence: true, if: :tax_bracket_zero_percent?
    validates :unit_price_with_tax, presence: true
    validates :active, presence: true

    money_attribute :gross_unit_price, :unit_price_with_tax

    private

    def tax_bracket_zero_percent?
      tax_bracket.present? && tax_bracket.percentage == 0
    end
  end
end