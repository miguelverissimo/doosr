module Accounting
  class TaxBracket < ApplicationRecord
    # Associations
    belongs_to :user
    has_many :receipt_items, class_name: "Accounting::ReceiptItem", dependent: :restrict_with_error
    has_many :invoice_items, class_name: "Accounting::InvoiceItem", dependent: :restrict_with_error
    has_many :invoice_template_items, class_name: "Accounting::InvoiceTemplateItem", dependent: :restrict_with_error

    # Validations
    validates :name, :percentage, presence: true
    validates :user, presence: true
    validates :name, uniqueness: { scope: :user_id }
  end
end
