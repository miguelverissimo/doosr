module MoneyPresentable
  extend ActiveSupport::Concern

  class_methods do
    # Declare integer attributes that are stored as cents but should
    # be presented in currency units (e.g. 1234 -> 12.34).
    #
    # This defines, for each attribute name:
    # - <name>_in_units  (numeric value in units)
    # - <name>_formatted (string with currency code and 2 decimals)
    def money_attribute(*names)
      names.each do |name|
        define_method("#{name}_in_units") do
          cents = self[name]
          return nil if cents.nil?

          BigDecimal(cents.to_s) / 100
        end

        define_method("#{name}_formatted") do
          amount = public_send("#{name}_in_units")
          return "" if amount.nil?

          currency_code = if respond_to?(:currency) && currency.present?
            currency
          elsif respond_to?(:invoice) && invoice&.respond_to?(:currency)
            invoice.currency
          else
            "EUR"
          end

          MoneyPresentable.format_currency(amount, currency_code)
        end

        define_method("#{name}_formatted_without_currency") do
          amount = public_send("#{name}_in_units")
          return "" if amount.nil?

          MoneyPresentable.format_currency_without_currency(amount)
        end
      end
    end
  end

  class << self
    # Very small formatting helper – no external gem.
    def format_currency(amount, currency_code)
      formatted_amount = format("%.2f", amount.to_f)
      "#{currency_code} #{formatted_amount}"
    end

    def format_currency_without_currency(amount)
      formatted_amount = format("%.2f", amount.to_f)
      formatted_amount
    end
  end
end


