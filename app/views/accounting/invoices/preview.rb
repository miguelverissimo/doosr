# frozen_string_literal: true

module Views
  module Accounting
    module Invoices
      class Preview < ::Views::Base
        def initialize(invoice:)
          @invoice = invoice
        end

        def view_template
          html(lang: "en") do
            head do
              meta(charset: "UTF-8")
              meta(name: "viewport", content: "width=device-width, initial-scale=1.0")
              title { "Invoice ##{@invoice.display_number}" }
              raw(view_context.stylesheet_link_tag("invoice_preview", media: "all", "data-turbo-track": "reload"))
            end

            body do
              div(class: "invoice-container") do
                render_header
                render_addresses
                render_invoice_number
                render_metadata
                render_items_table
                div(class: "spacer")
                hr(class: "section-divider")
                render_bottom_section
              end
            end
          end
        end

        private

        def render_header
          div(class: "header") do
            div(class: "logo-section") do
              render_logo
            end
          end
        end

        def render_logo
          logo = @invoice.invoice_template&.accounting_logo
          if logo&.image&.attached?
            img(
              class: "logo",
              alt: "Logo",
              src: view_context.url_for(logo.image)
            )
          else
            svg(class: "logo", viewBox: "0 0 100 100", xmlns: "http://www.w3.org/2000/svg") do
              # Laptop base
              rect(x: "15", y: "55", width: "70", height: "35", rx: "3", fill: "#000")
              rect(x: "20", y: "60", width: "60", height: "25", fill: "#fff")

              # Infinity symbol
              path(
                d: "M 35 72 Q 30 67 35 62 Q 40 67 35 72 M 35 72 Q 40 77 45 72 Q 50 67 55 72 Q 60 77 65 72 Q 70 67 65 62 Q 60 67 55 72 Q 50 77 45 72 Q 40 67 35 72",
                stroke: "#000",
                stroke_width: "2.5",
                fill: "none",
                stroke_linecap: "round",
                stroke_linejoin: "round"
              )

              # Stand
              rect(x: "10", y: "90", width: "80", height: "3", rx: "1", fill: "#000")
              path(d: "M 40 90 L 45 85 L 55 85 L 60 90", fill: "#000")
            end
          end
        end

        def render_provider_name
          provider = @invoice.provider
          if provider.name.present?
            provider.name.split("\n").each do |line|
              plain(line)
              br unless line == provider.name.split("\n").last
            end
          else
            plain("Provider")
          end
        end

        def render_addresses
          div(class: "addresses") do
            div(class: "from-address") do
              h2 { render_provider_name }
              render_address_lines(@invoice.provider.full_address)
              div(class: "address-line") { @invoice.provider.country.upcase }
              render_tax_id
            end

            div(class: "to-address") do
              h2 { "Bill to:" }
              div(class: "address-line") do
                strong { @invoice.customer.name }
              end
              if @invoice.customer.address
                render_address_lines(@invoice.customer.address.full_address)
                div(class: "address-line") { @invoice.customer.address.country.upcase }
              end
            end
          end
        end

        def render_address_lines(full_address)
          return if full_address.blank?

          full_address.to_s.split("\n").each do |line|
            div(class: "address-line") { line }
          end
        end

        def render_tax_id
          fiscal_info = @invoice.provider.fiscal_info
          if fiscal_info&.tax_number.present?
            div(class: "address-line tax-id") do
              span(class: "tax-id-label") { "Tax ID: " }
              plain(fiscal_info.tax_number)
            end
          end
        end

        def render_invoice_number
          div(class: "invoice-number") do
            span(class: "invoice-number-label") { "Invoice " }
            plain("# #{@invoice.display_number}")
          end
        end

        def render_metadata
          div(class: "metadata") do
            div(class: "metadata-item") do
              div(class: "metadata-label") { "Your Reference" }
              div(class: "metadata-value") { @invoice.customer_reference }
            end

            div(class: "metadata-item") do
              div(class: "metadata-label") { "Client Discount" }
              div(class: "metadata-value") { format_money(@invoice.discount) }
            end

            div(class: "metadata-item") do
              div(class: "metadata-label") { "Currency" }
              div(class: "metadata-value") { @invoice.currency }
            end

            div(class: "metadata-item") do
              div(class: "metadata-label") { "Exchange Rate" }
              div(class: "metadata-value") { "1.00" }
            end

            div(class: "metadata-item") do
              div(class: "metadata-label") { "Issue Date" }
              div(class: "metadata-value") { format_date(@invoice.issued_at) }
            end

            div(class: "metadata-item") do
              div(class: "metadata-label") { "Due Date" }
              div(class: "metadata-value") { format_date(@invoice.due_at) }
            end

            div(class: "metadata-item") do
              div(class: "metadata-label") { "Payment Terms" }
              div(class: "metadata-value") { payment_terms_display }
            end

            div(class: "metadata-item") do
              div(class: "metadata-label") { "Payment Method" }
              div(class: "metadata-value") { "Bank Transfer" }
            end
          end
        end

        def render_items_table
          div(class: "items-table-wrapper") do
            table(class: "items-table") do
            thead do
              tr do
                th(style: "width: 7%;") { "Ref." }
                th(style: "width: 38%;") { "Description" }
                th(style: "width: 8%;") { "Qty." }
                th(style: "width: 10%;") { "Unit" }
                th(style: "width: 12%;") { "Unit Price" }
                th(style: "width: 8%;") { "Disc." }
                th(style: "width: 8%;") { "Tax" }
                th(style: "width: 13%;") { "Amount" }
              end
            end
            tbody do
              @invoice.invoice_items.each do |invoice_item|
                tr do
                  td(class: "reference") { invoice_item.item.reference }
                  td(class: "left-align") { invoice_item.description }
                  td(class: "right-align") { format_number(invoice_item.quantity) }
                  td(class: "center-align") { invoice_item.unit }
                  td(class: "right-align") { format_money(invoice_item.unit_price) }
                  td(class: "right-align") { "#{format_number(invoice_item.discount_rate)}%" }
                  td(class: "right-align") { format_money(invoice_item.tax_amount) }
                  td(class: "right-align") { format_money(invoice_item.amount) }
                end
              end
            end
            end
          end
        end

        def render_bottom_section
          div(class: "bottom-section") do
            div(class: "left-column") do
              render_tax_summary
              render_payment_details
            end

            div(class: "right-column") do
              render_summary
            end
          end
        end

        def render_tax_summary
          div(class: "tax-summary") do
            h3 { "Tax Summary Table" }
            table(class: "tax-summary-table") do
              thead do
                tr do
                  th { "Tax/Rate" }
                  th { "Parcel" }
                  th { "Total" }
                  th { "Exemption motive" }
                end
              end
              tbody do
                tax_brackets_data.each do |bracket_data|
                  tr do
                    td { "#{bracket_data[:name]} (#{bracket_data[:percentage]}%)" }
                    td { format_money(bracket_data[:subtotal]) }
                    td { format_money(bracket_data[:tax_amount]) }
                    td { bracket_data[:exemption_motive] || "" }
                  end
                end
              end
            end
          end
        end

        def render_payment_details
          div(class: "payment-details") do
            if @invoice.bank_info.present?
              bank_info = @invoice.bank_info
              has_iban_combo = bank_info.iban.present? && bank_info.swift_bic.present?
              has_routing_combo = bank_info.routing_number.present? && bank_info.account_number.present?

              if has_iban_combo || has_routing_combo
                h3 { "Payment Details" }
                p do
                  if has_iban_combo
                    strong { "IBAN:" }
                    plain(" #{bank_info.iban}")
                    br
                    strong { "SWIFT/BIC:" }
                    plain(" #{bank_info.swift_bic}")
                  elsif has_routing_combo
                    strong { "Account Number:" }
                    plain(" #{bank_info.account_number}")
                    br
                    strong { "Routing Number:" }
                    plain(" #{bank_info.routing_number}")
                  end
                end
              end
            end
          end
        end

        def render_summary
          div(class: "summary") do
            totals_by_kind = @invoice.metadata&.dig("totals_by_kind") || {}

            render_summary_row("Services", totals_by_kind["service"] || 0)
            render_summary_row("Goods", totals_by_kind["product"] || 0)
            render_summary_row("Tools", totals_by_kind["tool"] || 0)
            render_summary_row("Equipment", totals_by_kind["equipment"] || 0)
            render_summary_row("Discounts", @invoice.discount)
            render_summary_row("Tax", @invoice.tax)
            render_summary_row("Advancements", 0)
            render_summary_row("Rounding", 0)
            render_summary_row("Total (#{@invoice.currency})", @invoice.total, total: true)
          end
        end

        def render_summary_row(label, amount_cents, total: false)
          div(class: "summary-row #{'total' if total}") do
            span(class: "summary-label") { label }
            span(class: "summary-value") { format_money(amount_cents) }
          end
        end

        def tax_brackets_data
          brackets = @invoice.metadata&.dig("totals_by_tax_bracket") || {}
          brackets.values.map do |bracket|
            {
              name: bracket["name"],
              percentage: bracket["percentage"],
              subtotal: bracket["subtotal"],
              tax_amount: bracket["tax_amount"],
              exemption_motive: "Outside the EU" # This could be stored in tax_bracket model later
            }
          end
        end

        def format_money(cents)
          return "0.00" if cents.nil? || cents == 0

          amount = BigDecimal(cents.to_s) / 100
          currency_symbol = case @invoice.currency
          when "EUR"
            "€"
          when "USD", "CAD"
            "$"
          else
            @invoice.currency
          end

          "#{currency_symbol}#{sprintf('%.2f', amount.to_f)}"
        end

        def format_date(date)
          return "" if date.nil?

          date.strftime("%b. %d, %Y")
        end

        def format_number(number)
          return "0.00" if number.nil?

          sprintf("%.2f", number.to_f)
        end

        def payment_terms_display
          payment_terms = @invoice.metadata&.dig("payment_terms")
          return "" if payment_terms.nil?

          "#{payment_terms} #{"day".pluralize(payment_terms)}"
        end
      end
    end
  end
end
