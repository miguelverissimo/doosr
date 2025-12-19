module Accounting
  class AccountingItem < ApplicationRecord
    belongs_to :user

    enum :kind, {
      product: :product,
      service: :service,
      tool: :tool,
      goods: :goods,
      equipment: :equipment,
      other: :other
    }, default: :service, validate: true

    enum :currency, {
      CAD: :CAD,
      EUR: :EUR,
      USD: :USD,
    }, default: :EUR, validate: true

    validates :reference, presence: true
    validates :name, presence: true
    validates :kind, presence: true, inclusion: { in: kinds.keys }
    validates :unit, presence: true
    validates :price, presence: true
  end
end