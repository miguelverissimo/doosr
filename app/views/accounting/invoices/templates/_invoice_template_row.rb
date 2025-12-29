module Views
  module Accounting
    module Invoices
      module Templates
        class InvoiceTemplateRow < ::Views::Base
          def initialize(invoice_template:)
            @invoice_template = invoice_template
          end

          def view_template
            div(
              id: "invoice_template_#{@invoice_template.id}_div",
              class: "flex flex-col w-full gap-2 rounded-md p-3 text-left transition-colors border border-border bg-muted hover:bg-muted/50 mt-2"
            ) do
              # first row: name + description + currency and buttons
              div(class: "flex flex-row items-center justify-between gap-2") do
                div(class: "flex flex-col items-start justify-between gap-2") do
                  div(class: "text-sm font-bold mt-1") { @invoice_template.name }
                  div(class: "text-sm text-muted-foreground mt-1") { @invoice_template.description }
                  div(class: "flex flex-row items-center gap-2 #{currency_color}") do
                    render_currency_icon
                    div(class: "text-sm font-bold mt-1") { @invoice_template.currency.upcase }
                  end
                  if @invoice_template.bank_info.present?
                    div(class: "flex flex-row items-center gap-2") do
                      render ::Components::Icon.new(name: :bank, size: "12", class: "w-5 h-5")
                      div(class: "text-sm font-bold mt-1") { @invoice_template.bank_info.name }
                    end
                  end
                end
                div(class: "flex flex-row items-center justify-between gap-2") do
                  div(class: "flex flex-row items-center justify-between gap-2") do
                    # Create invoice from template button
                    render_create_invoice_dialog

                    render RubyUI::Dialog.new do
                      render RubyUI::DialogTrigger.new do
                        Button(variant: :outline, icon: true) do
                          render ::Components::Icon.new(name: :edit, size: "12", class: "w-5 h-5")
                        end
                      end
                      render_edit_dialog
                    end

                    render_delete_confirmation_dialog
                  end
                end
              end

              div(class: "mt-1 flex flex-row items-start gap-4") do
                # left column: logo + provider address
                div(class: "flex-1 min-w-0 space-y-1") do
                  label(class: "text-md font-bold") { "Provider" }
                  div(class: "flex-1 min-w-0 space-y-1") do
                    if @invoice_template.accounting_logo.image.attached?
                      div(
                        class: "w-full sm:w-[250px] sm:max-w-[250px] shrink-0 rounded-md border shadow-sm bg-neutral-300 p-2 flex items-center justify-center",
                        style: "background-color: rgb(212 212 212);"
                      ) do
                        img(
                          alt: "Logo",
                          loading: "lazy",
                          class: "max-w-full max-h-full object-contain",
                          style: "max-width: 100%; max-height: 100%;",
                          src: view_context.url_for(@invoice_template.accounting_logo.image)
                        )
                      end
                    else
                      div(class: "text-sm text-gray-500") { "No image attached" }
                    end
                  end
                  div(class: "flex-1 min-w-0 space-y-1") do
                    div(class: "text-sm font-bold") { @invoice_template.provider_address.name }
                  end
                  div(class: "flex-1 min-w-0 space-y-1") do
                    div(class: "text-sm") do
                      @invoice_template.provider_address.full_address.to_s.split("\n").each_with_index do |line, index|
                        span { line }
                        br if index < @invoice_template.provider_address.full_address.to_s.split("\n").length - 1
                      end
                    end
                    div(class: "text-sm font-bold mt-1") { @invoice_template.provider_address.country.upcase }
                  end
                end

                # right column: customer
                div(class: "mt-1 flex flex-col gap-2") do
                  label(class: "text-md font-bold") { "Customer" }
                  div(class: "flex-1 min-w-0 space-y-1") do
                    div(class: "text-sm font-bold") { @invoice_template.customer.name }
                  end
                  div(class: "flex-1 min-w-0 space-y-1") do
                    div(class: "text-sm") do
                      @invoice_template.customer.address.full_address.to_s.split("\n").each_with_index do |line, index|
                        span { line }
                        br if index < @invoice_template.customer.address.full_address.to_s.split("\n").length - 1
                      end
                    end
                  end
                end
              end
            end
          end

          def render_edit_dialog
            render RubyUI::DialogContent.new(size: :lg) do
              render RubyUI::DialogHeader.new do
                render RubyUI::DialogTitle.new { "Edit Invoice Template" }
              end

              render RubyUI::DialogMiddle.new do
                render ::Components::Accounting::Invoices::Templates::Form.new(invoice_template: @invoice_template)
              end
            end
          end

          def render_delete_confirmation_dialog
            render RubyUI::AlertDialog.new do
              render RubyUI::AlertDialogTrigger.new do
                Button(variant: :destructive, icon: true) do
                  render ::Components::Icon.new(name: :delete, size: "12", class: "w-5 h-5")
                end
              end

              render RubyUI::AlertDialogContent.new do
                render RubyUI::AlertDialogHeader.new do
                  render RubyUI::AlertDialogTitle.new { "Are you sure you want to delete #{@invoice_template.name}?" }
                  render RubyUI::AlertDialogDescription.new { "This action cannot be undone. This will permanently delete the invoice template." }
                end

                render RubyUI::AlertDialogFooter.new(class: "mt-6 flex flex-row justify-end gap-3") do
                  render RubyUI::AlertDialogCancel.new { "Cancel" }

                  form(
                    action: view_context.invoice_template_path(@invoice_template),
                    method: "post",
                    data: {
                      turbo_method: :delete,
                      action: "submit@document->ruby-ui--alert-dialog#dismiss"
                    },
                    class: "inline",
                    id: "delete_invoice_template_#{@invoice_template.id}"
                  ) do
                    input(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)
                    input(type: :hidden, name: "_method", value: "delete")
                    render RubyUI::AlertDialogAction.new(type: "submit", variant: :destructive) { "Delete" }
                  end
                end
              end
            end
          end

          def render_currency_icon
            case @invoice_template.currency
            when "EUR"
              render ::Components::Icon.new(name: :currency_euro, size: "12", class: "w-5 h-5")
            when "USD"
              render ::Components::Icon.new(name: :currency_usd, size: "12", class: "w-5 h-5")
            when "CAD"
              render ::Components::Icon.new(name: :currency_cad, size: "12", class: "w-5 h-5")
            end
          end

          def currency_color
            case @invoice_template.currency
            when "EUR"
              "text-green-500"
            when "USD"
              "text-blue-500"
            when "CAD"
              "text-red-500"
            end
          end

          def render_create_invoice_dialog
            render RubyUI::Dialog.new do
              render RubyUI::DialogTrigger.new do
                Button(variant: :primary, icon: true) do
                  render ::Components::Icon.new(name: :new_invoice, size: "12", class: "w-5 h-5")
                end
              end

              render RubyUI::DialogContent.new(size: :lg) do
                render RubyUI::DialogHeader.new do
                  render RubyUI::DialogTitle.new { "Create Invoice from Template" }
                  render RubyUI::DialogDescription.new { "Create a new invoice based on #{@invoice_template.name}" }
                end

                render RubyUI::DialogMiddle.new do
                  render ::Components::Accounting::Invoices::FromTemplateForm.new(invoice_template: @invoice_template)
                end
              end
            end
          end
        end
      end
    end
  end
end
