module Views
  module Accounting
    module Customers
      class CustomerRow < ::Views::Base
        def initialize(customer:)
          @customer = customer
        end

        def view_template
          div(
            id: "customer_#{@customer.id}_div",
            class: "flex flex-col w-full gap-2 rounded-md p-3 text-left transition-colors border border-border bg-muted hover:bg-muted/50"
          ) do
            div(class: "flex flex-row items-center justify-between gap-2") do
              div(class: "text-md font-bold mt-1") { @customer.name }

              # Right column: buttons
              div(class: "flex items-center gap-2 shrink-0") do
                # Edit button with dialog
                render RubyUI::Dialog.new do
                  render RubyUI::DialogTrigger.new do
                    Button(variant: :outline, icon: true) do
                      render ::Components::Icon::Edit.new(size: "12", class: "w-5 h-5")
                    end
                  end
                  render_edit_dialog
                end

                # Delete button with AlertDialog confirmation
                render_delete_confirmation_dialog
              end
            end

            div(class: "mt-1 flex flex-row gap-4") do
              # Address column
              div(class: "flex-1 min-w-0 space-y-1") do
                h3(class: "text-sm font-bold") { "Address" }
                div(class: "text-sm") do
                  @customer.address.full_address.to_s.split("\n").each_with_index do |line, index|
                    span { line }
                    br if index < @customer.address.full_address.to_s.split("\n").length - 1
                  end
                end
                div(class: "text-sm font-bold mt-1") { @customer.address.country.upcase }
                if @customer.address.fiscal_info.present?
                  div(class: "text-sm mt-1") do
                    span(class: "text-muted-foreground font-bold") { plain("Tax number: ") }
                    plain(@customer.address.fiscal_info.tax_number)
                  end
                end
              end
            end

            div(class: "mt-1 flex flex-row gap-4 mb-2") do
              # Contact Information column
              div(class: "flex-1 flex flex-col gap-2") do
                h3(class: "text-sm font-bold") { "Contact Information" }
                div(class: "flex flex-col gap-1 text-sm") do
                  div(class: "flex items-center gap-2") do
                    render ::Components::Icon::User.new(size: "16", class: "shrink-0")
                    span { @customer.contact_name }
                  end
                  div(class: "flex items-center gap-2") do
                    render ::Components::Icon::Email.new(size: "16", class: "shrink-0")
                    span { @customer.contact_email }
                  end
                  div(class: "flex items-center gap-2") do
                    render ::Components::Icon::Phone.new(size: "16", class: "shrink-0")
                    if @customer.telephone.present?
                      span { @customer.telephone }
                    else
                      span(class: "italic") { "not provided" }
                    end
                  end
                end
              end

              # Billing Information column
              div(class: "flex-1 flex flex-col gap-2") do
                h3(class: "text-sm font-bold") { "Billing Information" }
                div(class: "flex flex-col gap-1 text-sm") do
                  div(class: "flex items-center gap-2") do
                    render ::Components::Icon::User.new(size: "16", class: "shrink-0")
                    span { @customer.billing_contact_name }
                  end
                  div(class: "flex items-center gap-2") do
                    render ::Components::Icon::Email.new(size: "16", class: "shrink-0")
                    span { @customer.billing_email }
                  end
                  div(class: "flex items-center gap-2") do
                    render ::Components::Icon::Phone.new(size: "16", class: "shrink-0")
                    if @customer.billing_phone.present?
                      span { @customer.billing_phone }
                    else
                      span(class: "italic") { "not provided" }
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
              render RubyUI::DialogTitle.new { "Edit Customer" }
              render RubyUI::DialogDescription.new { "Update the customer information" }
            end

            render RubyUI::DialogMiddle.new do
              render ::Components::Accounting::Customers::Form.new(customer: @customer)
            end
          end
        end

        def render_delete_confirmation_dialog
          render RubyUI::AlertDialog.new do
            render RubyUI::AlertDialogTrigger.new do
              Button(variant: :destructive, icon: true) do
                render ::Components::Icon::Delete.new(size: "12", class: "w-5 h-5")
              end
            end

            render RubyUI::AlertDialogContent.new do
              render RubyUI::AlertDialogHeader.new do
                render RubyUI::AlertDialogTitle.new { "Are you sure you want to delete #{@customer.name}?" }
                render RubyUI::AlertDialogDescription.new { "This action cannot be undone. This will permanently delete the customer." }
              end

              render RubyUI::AlertDialogFooter.new(class: "mt-6 flex flex-row justify-end gap-3") do
                render RubyUI::AlertDialogCancel.new { "Cancel" }

                form(
                  action: view_context.customer_path(@customer),
                  method: "post",
                  data: { turbo_method: :delete, action: "submit@document->ruby-ui--alert-dialog#dismiss" },
                  class: "inline",
                  id: "delete_customer_#{@customer.id}"
                ) do
                  input(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)
                  input(type: :hidden, name: "_method", value: "delete")
                  render RubyUI::AlertDialogAction.new(type: "submit", variant: :destructive) { "Delete" }
                end
              end
            end
          end
        end
      end
    end
  end
end
