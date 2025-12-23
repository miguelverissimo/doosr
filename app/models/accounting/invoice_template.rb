module Accounting
  class InvoiceTemplate < ApplicationRecord
    belongs_to :user
    belongs_to :accounting_logo, class_name: "Accounting::AccountingLogo"
    belongs_to :provider_address, class_name: "Address"
    belongs_to :customer, class_name: "Accounting::Customer"
    belongs_to :bank_info, optional: true, class_name: "Accounting::BankInfo"

    has_many :invoice_template_items, dependent: :destroy, class_name: "Accounting::InvoiceTemplateItem"
    accepts_nested_attributes_for :invoice_template_items, allow_destroy: true

    enum :currency, {
      CAD: :CAD,
      EUR: :EUR,
      USD: :USD
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
