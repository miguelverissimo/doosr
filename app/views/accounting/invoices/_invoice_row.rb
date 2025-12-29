module Views
  module Accounting
    module Invoices
      class InvoiceRow < Views::Base
        def initialize(invoice:, receipt_items: {}, available_invoices: [])
          @invoice = invoice
          @receipt_items = receipt_items
          @available_invoices = available_invoices
        end

        def view_template
          div(
            id: "invoice_#{@invoice.id}_div", 
            class: "flex flex-col w-full gap-2 rounded-md p-3 text-left transition-colors border border-border bg-muted hover:bg-muted/50",
            data: { controller: "mark-invoice-paid" }
          ) do
            div(class: "flex flex-col gap-2") do
              div(class: "flex flex-row items-center justify-between w-full gap-2") do
                div(class: "text-xl") do 
                  span(class: "font-bold") { plain("Invoice # ") }
                  plain(@invoice.display_number)
                end
                render_state_badge
              end
              div(class: "flex flex-row items-center justify-between w-full gap-2") do
                div(class: "flex flex-row items-center gap-2") do
                  render Components::Icon.new(name: :created_date, size: "12", class: "w-5 h-5")
                  div(class: "text-sm font-bold") { @invoice.created_at.strftime("%d/%m/%Y") }
                end
                div(class: "flex flex-row items-center gap-2") do
                  render Components::Icon.new(name: :due_date, size: "12", class: "w-5 h-5")
                  div(class: "text-sm font-bold") { @invoice.due_at.strftime("%d/%m/%Y") }
                  if @invoice.state != "paid"
                    if @invoice.overdue?
                      render RubyUI::Badge.new(variant: :red, size: :md) { "Overdue for #{@invoice.days_until_due}" }
                    elsif @invoice.days_until_due
                      render RubyUI::Badge.new(variant: :lime, size: :md) { "Due #{@invoice.days_until_due}" }
                    end
                  end
                end
              end
              div(class: "flex flex-row items-start gap-2") do
                render_items_table
              end
              
              div(class: "flex flex-row items-center justify-between gap-2") do
                render_buttons

                div(class: "flex flex-row items-end justify-end gap-2 text-xl font-bold") do
                  div(class: "flex flex-row items-center gap-2 #{currency_color}") do
                    render_currency_icon
                    div(class: "text-md font-bold") { @invoice.currency.upcase }
                  end 
                  plain(" ")
                  plain(@invoice.total_formatted_without_currency)
                end
              end
            end
          end
        end

        def render_items_table
          Table do
            TableHeader do
              TableRow do
                TableHead { span(class: "text-xs") { "Ref." } }
                TableHead { span(class: "text-xs") { "Description" } }
                TableHead { span(class: "text-xs") { "Qty." } }
                TableHead { span(class: "text-xs") { "Unit" } }
                TableHead { span(class: "text-xs") { "Unit Price" } }
                TableHead { span(class: "text-xs") { "Disc." } }
                TableHead { span(class: "text-xs") { "Tax" } }
                TableHead { span(class: "text-xs") { "Amount" } }
              end
            end
            TableBody do
              @invoice.invoice_items.each do |invoice_item|
                TableRow do
                  TableCell { span(class: "text-xs") { invoice_item.item.reference } }
                  TableCell { span(class: "text-xs") { invoice_item.description } }
                  TableCell { span(class: "text-xs") { invoice_item.quantity } }
                  TableCell { span(class: "text-xs") { invoice_item.unit } }
                  TableCell { span(class: "text-xs") { invoice_item.unit_price_formatted_without_currency } }
                  TableCell { span(class: "text-xs") { invoice_item.discount_amount_formatted_without_currency } }
                  TableCell { span(class: "text-xs") { invoice_item.tax_amount_formatted_without_currency } }
                  TableCell { span(class: "text-xs") { invoice_item.amount_formatted_without_currency } }
                end
              end
            end
          end
        end

        def render_buttons
          div(class: "flex flex-row gap-2 mt-2 justify-end") do
            # Mark as draft (only enabled if not already draft)
            form(
              action: view_context.invoice_path(@invoice),
              method: "post",
              class: "inline-flex",
              data: {
                controller: "invoice-state",
                invoice_state_state_value: "draft",
                action: "submit->invoice-state#submit"
              }
            ) do
              input(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)
              input(type: :hidden, name: "_method", value: "patch")
              input(type: :hidden, name: "state", value: "draft")
              Button(
                variant: :tinted,
                tint: :sky,
                size: :md,
                type: :submit,
                icon: true,
                disabled: @invoice.state == "draft"
              ) { render Components::Icon.new(name: :draft, size: "12", class: "w-4 h-4") }
            end

            # Mark as sent (only if currently draft)
            form(
              action: view_context.invoice_path(@invoice),
              method: "post",
              class: "inline-flex",
              data: {
                controller: "invoice-state",
                invoice_state_state_value: "sent",
                action: "submit->invoice-state#submit"
              }
            ) do
              input(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)
              input(type: :hidden, name: "_method", value: "patch")
              input(type: :hidden, name: "state", value: "sent")
              Button(
                variant: :tinted,
                tint: :amber,
                size: :md,
                type: :submit,
                icon: true,
                disabled: @invoice.state != "draft"
              ) { render Components::Icon.new(name: :send, size: "12", class: "w-4 h-4") }
            end

            # Mark as paid (only if currently sent) - with receipt prompt
            form(
              action: view_context.invoice_path(@invoice),
              method: "post",
              class: "inline-flex",
              data: { action: "submit->mark-invoice-paid#submit" }
            ) do
              input(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)
              input(type: :hidden, name: "_method", value: "patch")
              input(type: :hidden, name: "state", value: "paid")
              Button(
                variant: :tinted,
                tint: :lime,
                size: :md,
                type: :submit,
                icon: true,
                disabled: @invoice.state != "sent"
              ) { render Components::Icon.new(name: :paid, size: "12", class: "w-4 h-4") }
            end

            # Preview button (always active) - opens preview in new tab
            a(
              href: view_context.preview_invoice_path(@invoice),
              target: "_blank",
              rel: "noopener noreferrer",
              class: "inline-flex"
            ) do
              Button(
                variant: :tinted,
                tint: :cyan,
                size: :md,
                type: :button,
                icon: true
              ) do
                render Components::Icon.new(name: :eye, size: "12", class: "w-4 h-4")
              end
            end

            # PDF download button (always active) - downloads PDF
            div(data: { controller: "pdf-download" }) do
              a(
                href: view_context.pdf_invoice_path(@invoice),
                download: "Invoice_#{@invoice.display_number.gsub('/', '-')}.pdf",
                class: "inline-flex",
                data: { action: "click->pdf-download#download" }
              ) do
                Button(
                  variant: :tinted,
                  tint: :fuchsia,
                  size: :md,
                  type: :button,
                  icon: true,
                  data: { pdf_download_target: "button" }
                ) do
                  render Components::Icon.new(name: :download, size: "12", class: "w-4 h-4")
                end
              end
            end

            # Edit button (only active in draft) - opens full edit dialog
            render RubyUI::Dialog.new do
              render RubyUI::DialogTrigger.new do
                Button(
                  variant: :outline,
                  size: :md,
                  type: :button,
                  icon: true,
                  disabled: @invoice.state != "draft"
                ) do
                  render Components::Icon.new(name: :edit, size: "12", class: "w-4 h-4")
                end
              end

              render RubyUI::DialogContent.new(size: :lg) do
                render RubyUI::DialogHeader.new do
                  render RubyUI::DialogTitle.new { "Edit Invoice #{@invoice.display_number}" }
                end

                render RubyUI::DialogMiddle.new do
                  render Components::Accounting::Invoices::Form.new(invoice: @invoice)
                end
              end
            end

            # View receipts button (disabled if no receipts)
            render RubyUI::Dialog.new do
              render RubyUI::DialogTrigger.new do
                Button(
                  variant: :outline,
                  size: :md,
                  type: :button,
                  icon: true,
                  disabled: @invoice.receipts.empty?
                ) do
                  render Components::Icon.new(name: :list, size: "12", class: "w-4 h-4")
                end
              end

              render RubyUI::DialogContent.new(size: :lg) do
                render RubyUI::DialogHeader.new do
                  render RubyUI::DialogTitle.new { "Receipts for Invoice #{@invoice.display_number}" }
                  render RubyUI::DialogDescription.new do
                    "All receipts associated with this invoice"
                  end
                end

                render RubyUI::DialogMiddle.new do
                  render Views::Accounting::Invoices::ReceiptsList.new(invoice: @invoice)
                end
              end
            end

            # Delete with confirmation (always active)
            render RubyUI::AlertDialog.new do
              render RubyUI::AlertDialogTrigger.new do
                Button(
                  variant: :destructive, 
                  size: :md, 
                  icon: true
                ) { render Components::Icon.new(name: :delete, size: "12", class: "w-4 h-4") }
              end

              render RubyUI::AlertDialogContent.new do
                render RubyUI::AlertDialogHeader.new do
                  render RubyUI::AlertDialogTitle.new { "Delete invoice #{@invoice.display_number}?" }
                  render RubyUI::AlertDialogDescription.new do
                    "This action cannot be undone. This will permanently delete the invoice."
                  end
                end

                render RubyUI::AlertDialogFooter.new(class: "mt-4 flex flex-row justify-end gap-3") do
                  render RubyUI::AlertDialogCancel.new { "Cancel" }

                  form(
                    action: view_context.invoice_path(@invoice),
                    method: "post",
                    data: {
                      turbo_method: :delete,
                      action: "submit@document->ruby-ui--alert-dialog#dismiss"
                    },
                    class: "inline-flex"
                  ) do
                    input(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)
                    input(type: :hidden, name: "_method", value: "delete")
                    render RubyUI::AlertDialogAction.new(type: "submit", variant: :destructive) { "Delete" }
                  end
                end
              end
            end

            # Receipt prompt dialogs (hidden, shown via Stimulus)
            render_receipt_prompt_dialogs
          end
        end

        def render_receipt_prompt_dialogs
          # Alert dialog asking if user wants to add a receipt
          render RubyUI::AlertDialog.new(
            data: { mark_invoice_paid_target: "alertDialog" }
          ) do
            render RubyUI::AlertDialogContent.new do
              render RubyUI::AlertDialogHeader.new do
                render RubyUI::AlertDialogTitle.new { "Add Receipt?" }
                render RubyUI::AlertDialogDescription.new do
                  "Would you like to create a receipt for this payment?"
                end
              end

              render RubyUI::AlertDialogFooter.new(class: "mt-4 flex flex-row justify-end gap-3") do
                render RubyUI::AlertDialogCancel.new(
                  data: { action: "click->mark-invoice-paid#cancelReceipt" }
                ) { "Cancel" }
                render RubyUI::AlertDialogAction.new(
                  data: { action: "click->mark-invoice-paid#confirmReceipt" }
                ) { "Yes, Add Receipt" }
              end
            end
          end

          # Choice dialog for selecting form type
          render RubyUI::Dialog.new(
            data: { mark_invoice_paid_target: "choiceDialog" }
          ) do
            render RubyUI::DialogContent.new(size: :md) do
              render RubyUI::DialogHeader.new do
                render RubyUI::DialogTitle.new { "Choose Receipt Form" }
                render RubyUI::DialogDescription.new do
                  "How would you like to create the receipt?"
                end
              end

              render RubyUI::DialogMiddle.new do
                div(class: "flex flex-col gap-3") do
                  Button(
                    variant: :primary,
                    type: :button,
                    class: "w-full",
                    data: { 
                      action: "click->mark-invoice-paid#openCalculatorForm",
                      receipt_choice: "calculator"
                    }
                  ) { "With Calculator" }
                  Button(
                    variant: :outline,
                    type: :button,
                    class: "w-full",
                    data: { 
                      action: "click->mark-invoice-paid#openSimpleForm",
                      receipt_choice: "simple"
                    }
                  ) { "Simple Form" }
                end
              end

              render RubyUI::DialogFooter.new do
                Button(
                  variant: :outline,
                  type: :button,
                  data: { 
                    action: "click->mark-invoice-paid#cancelChoice",
                    receipt_choice: "cancel"
                  }
                ) { "Cancel" }
              end
            end
          end

          # Calculator form dialog
          render RubyUI::Dialog.new(
            data: { mark_invoice_paid_target: "calculatorDialog" }
          ) do
            render RubyUI::DialogContent.new(size: :lg) do
              render RubyUI::DialogHeader.new do
                render RubyUI::DialogTitle.new { "Add Receipt with Calculator" }
                render RubyUI::DialogDescription.new { "Create a new receipt using the calculator" }
              end

              render RubyUI::DialogMiddle.new do
                render Components::Accounting::Receipts::FormWithCalculator.new(
                  invoice: @invoice,
                  receipt_items: @receipt_items,
                  available_invoices: @available_invoices
                )
              end
            end
          end

          # Simple form dialog
          render RubyUI::Dialog.new(
            data: { mark_invoice_paid_target: "simpleDialog" }
          ) do
            render RubyUI::DialogContent.new(size: :lg) do
              render RubyUI::DialogHeader.new do
                render RubyUI::DialogTitle.new { "Add Receipt" }
                render RubyUI::DialogDescription.new { "Create a new receipt" }
              end

              render RubyUI::DialogMiddle.new do
                render Components::Accounting::Receipts::Form.new(
                  invoice: @invoice,
                  receipt_items: @receipt_items,
                  available_invoices: @available_invoices
                )
              end
            end
          end
        end

        def render_state_badge
          variant = case @invoice.state
            when "draft"
              :sky
            when "sent"
              :fuchsia
            when "partial"
              :amber
            when "paid"
              :lime
            else
              :red
            end
          
          render RubyUI::Badge.new(variant: variant, size: :lg) { @invoice.state.capitalize }
        end

        def render_currency_icon(size: "12")
          case @invoice.currency
          when "EUR"
            render Components::Icon.new(name: :currency_euro, size: size, class: "w-5 h-5")
          when "USD"
            render Components::Icon.new(name: :currency_usd, size: size, class: "w-5 h-5")
          when "CAD"
            render Components::Icon.new(name: :currency_cad, size: size, class: "w-5 h-5")
          end
        end

        def currency_color
          case @invoice.currency
          when "EUR"
            "text-green-500"
          when "USD"
            "text-blue-500"
          when "CAD"
            "text-red-500"
          end
        end
      end
    end
  end
end