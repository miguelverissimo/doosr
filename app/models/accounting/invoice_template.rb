module Accounting
  class InvoiceTemplate < ApplicationRecord
    belongs_to :user
    belongs_to :accounting_logo
    belongs_to :provider_address, class_name: "Address"
    belongs_to :customer

    enum :currency, {
      CAD: :CAD,
      EUR: :EUR,
      USD: :USD,
    }, default: :EUR, validate: true

    validates :name, presence: true
    validates :description, presence: true
    validates :accounting_logo, presence: true
    validates :provider_address, presence: true
    validates :customer, presence: true
    validates :currency, presence: true
    validates :currency, inclusion: { in: currencies.keys }
  end
end
