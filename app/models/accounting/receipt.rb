module Accounting
  class Receipt < ApplicationRecord
    include MoneyPresentable

    belongs_to :user
    belongs_to :invoice, optional: true, class_name: "Accounting::Invoice"
    has_many :items, class_name: "Accounting::ReceiptReceiptItem", dependent: :destroy
    has_many :receipt_items, through: :items, source: :receipt_item, class_name: "Accounting::ReceiptItem"

    has_one_attached :document

    enum :kind, {
      receipt: :receipt,
      invoice_receipt: :invoice_receipt
    }, default: :receipt, validate: true

    enum :payment_type, {
      total: :total,
      partial: :partial
    }, default: :total, validate: true

    validates :kind, presence: true
    validates :kind, inclusion: { in: kinds.keys }
    validates :payment_type, presence: true
    validates :payment_type, inclusion: { in: payment_types.keys }

    validates :reference, presence: true
    validates :issue_date, presence: true
    validates :payment_date, presence: true
    validates :value, presence: true

    validate :document_validation, if: -> { document.attached? }

    money_attribute :value

    private

    def document_validation
      if document.attached?
        unless document.content_type == "application/pdf"
          errors.add(:document, "must be a PDF")
        end

        if document.byte_size > 10.megabytes
          errors.add(:document, "must be less than 10MB")
        end
      end
    end
  end
end
