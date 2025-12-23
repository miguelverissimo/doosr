module Accounting
  class Invoice < ApplicationRecord
    include MoneyPresentable

    belongs_to :user
    belongs_to :invoice_template, optional: true, class_name: "Accounting::InvoiceTemplate"
    belongs_to :customer, class_name: "Accounting::Customer"
    belongs_to :provider, class_name: "Address"
    belongs_to :bank_info, optional: true, class_name: "Accounting::BankInfo"

    enum :state, {
      draft: :draft,
      sent: :sent,
      paid: :paid
    }, default: :draft, validate: true

    enum :currency, {
      CAD: :CAD,
      EUR: :EUR,
      USD: :USD
    }, default: :EUR, validate: true

    validates :number, presence: true
    validates :year, presence: true
    validates :display_number, presence: true
    validates :provider, presence: true
    validates :customer, presence: true
    validates :currency, presence: true
    validates :currency, inclusion: { in: currencies.keys }

    # Associations
    has_many :invoice_items, dependent: :destroy

    money_attribute :subtotal, :discount, :tax, :total

    before_validation :ensure_display_number
    before_save :update_payment_terms_metadata

    # Check if the invoice is overdue
    def overdue?
      return false if due_at.nil?

      due_at.to_date < Date.today
    end

    # Calculate days until due date, returning a formatted string
    # Returns "Today" if due date is today, or "x days" (with proper capitalization)
    def days_until_due
      return nil if due_at.nil?

      due_date = due_at.to_date
      today = Date.today
      days = (due_date - today).to_i

      if days == 0
        "Today"
      elsif days > 1
        "in #{days} #{"day".pluralize(days)}"
      else
        # Negative days (overdue) - return absolute value
        abs_days = days.abs
        "#{abs_days} #{"day".pluralize(abs_days)}"
      end
    end

    # Recalculate monetary totals and metadata based on current invoice_items.
    # This should be called only when invoice_items change (see callbacks on InvoiceItem).
    def recalculate_totals!
      items = invoice_items.includes(:item, :tax_bracket)

      subtotal_cents = items.sum(&:subtotal)
      discount_cents = items.sum(&:discount_amount)
      tax_cents = items.sum(&:tax_amount)
      total_cents = items.sum(&:amount)

      # Per-kind totals (service, product, tool, equipment, other, goods, etc.)
      by_kind_cents = Hash.new(0)
      items.each do |invoice_item|
        kind = invoice_item.item&.kind
        next if kind.blank?

        by_kind_cents[kind] += invoice_item.amount
      end

      # Per-tax-bracket aggregation of subtotal and tax_amount
      by_tax_bracket_cents = {}
      items.each do |invoice_item|
        bracket = invoice_item.tax_bracket
        next unless bracket

        key = bracket.id.to_s
        entry = (by_tax_bracket_cents[key] ||= {
          "name" => bracket.name,
          "percentage" => bracket.percentage.to_f,
          "subtotal" => 0,
          "tax_amount" => 0
        })

        entry["subtotal"] += invoice_item.subtotal
        entry["tax_amount"] += invoice_item.tax_amount
      end

      new_metadata = (metadata || {}).dup
      new_metadata["totals_by_kind"] = by_kind_cents
      new_metadata["totals_by_tax_bracket"] = by_tax_bracket_cents

      # Persist without triggering validations again
      update_columns(
        subtotal: subtotal_cents,
        discount: discount_cents,
        tax: tax_cents,
        total: total_cents,
        metadata: new_metadata,
        updated_at: Time.current
      )
    end

    private

    def ensure_display_number
      return unless number.present? && year.present?

      self.display_number = "#{number}/#{year}"
    end

    def update_payment_terms_metadata
      return if issued_at.nil? || due_at.nil?

      days = (due_at.to_date - issued_at.to_date).to_i
      new_metadata = (metadata || {}).dup
      new_metadata["payment_terms"] = days
      self.metadata = new_metadata
    end
  end
end
