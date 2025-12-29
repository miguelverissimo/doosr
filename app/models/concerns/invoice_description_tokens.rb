module InvoiceDescriptionTokens
  # Interpolate contextual tokens in a description using invoice data.
  #
  # Supported tokens:
  # - {month}   -> full month name from invoice.issued_at (or today)
  # - {year}    -> year from invoice.issued_at (or today)
  # - {quarter} -> Q1, Q2, Q3, Q4 based on invoice.issued_at (or today)
  def self.interpolate_description(description, invoice)
    return description if description.blank? || invoice.nil?

    date = invoice.issued_at&.to_date || Date.current

    month   = date.strftime("%B")
    year    = date.year.to_s
    quarter_number = ((date.month - 1) / 3) + 1
    quarter = "Q#{quarter_number}"

    description
      .gsub("{month}", month)
      .gsub("{year}", year)
      .gsub("{quarter}", quarter)
  end
end
