module Views
  module Accounting
    module Invoices
        class List < ::Views::Base
          def initialize(user:, filter: "unpaid", page: 1, search_query: nil, date_from: nil, date_to: nil)
            @user = user
            @filter = filter
            @page = page
            @search_query = search_query
            @date_from = date_from
            @date_to = date_to
          end

          def view_template
            div(class: "flex flex-col gap-4", id: "invoices_filter_section", data: { controller: "invoice-filter" }) do
              # Header with title and create buttons
              div(class: "flex items-center justify-between mb-4") do
                h3(class: "text-lg font-semibold") { "Invoices" }
                div(class: "flex gap-2") do
                  render_invoice_form_dialog
                  render_invoice_from_template_dialog
                end
              end

              # Search form
              render_search_form

              # Filter buttons
              div(class: "flex gap-2") do
                render ::Components::BadgeLink.new(
                  href: view_context.invoices_path(filter: "unpaid"),
                  variant: :sky,
                  active: @filter == "unpaid",
                  data: {
                    turbo_stream: true,
                    action: "click->invoice-filter#showSpinner"
                  },
                  id: "filter_unpaid"
                ) { "Unpaid" }

                render ::Components::BadgeLink.new(
                  href: view_context.invoices_path(filter: "paid"),
                  variant: :lime,
                  active: @filter == "paid",
                  data: {
                    turbo_stream: true,
                    action: "click->invoice-filter#showSpinner"
                  },
                  id: "filter_paid"
                ) { "Paid" }

                render ::Components::BadgeLink.new(
                  href: view_context.invoices_path(filter: "all"),
                  variant: :rose,
                  active: @filter == "all",
                  data: {
                    turbo_stream: true,
                    action: "click->invoice-filter#showSpinner"
                  },
                  id: "filter_all"
                ) { "All" }
              end

              # Loading spinner (hidden by default)
              div(
                id: "invoices_loading_spinner",
                class: "hidden",
                data: { invoice_filter_target: "spinner" }
              ) do
                render ::Components::Shared::LoadingSpinner.new(message: "Loading invoices...")
              end

              # Invoice content
              div(data: { invoice_filter_target: "content" }) do
                render ::Views::Accounting::Invoices::ListContent.new(
                  user: @user,
                  filter: @filter,
                  page: @page,
                  search_query: @search_query,
                  date_from: @date_from,
                  date_to: @date_to
                )
              end
            end
          end

          private

          def render_invoice_form_dialog
            invoice = @user.invoices.build
            render RubyUI::Dialog.new do
              render RubyUI::DialogTrigger.new do
                Button(variant: :primary, size: :sm) { "Add Invoice" }
              end

              render RubyUI::DialogContent.new(size: :lg) do
                render RubyUI::DialogHeader.new do
                  render RubyUI::DialogTitle.new { "Add Invoice" }
                  render RubyUI::DialogDescription.new { "Create a new invoice" }
                end

                render RubyUI::DialogMiddle.new do
                  render ::Components::Accounting::Invoices::Form.new(invoice: invoice)
                end
              end
            end
          end

          def render_invoice_from_template_dialog
            render RubyUI::Dialog.new do
              render RubyUI::DialogTrigger.new do
                Button(variant: :secondary, size: :sm) { "From Template" }
              end

              render RubyUI::DialogContent.new(size: :lg) do
                render RubyUI::DialogHeader.new do
                  render RubyUI::DialogTitle.new { "Create Invoice from Template" }
                  render RubyUI::DialogDescription.new { "Select a template to create an invoice" }
                end

                render RubyUI::DialogMiddle.new do
                  render ::Components::Accounting::Invoices::FromTemplateForm.new(user: @user)
                end
              end
            end
          end

          def render_search_form
            form(
              action: view_context.invoices_path,
              method: "get",
              data: {
                turbo_stream: true,
                action: "submit->invoice-filter#showSpinner"
              },
              class: "space-y-3"
            ) do
              input(type: "hidden", name: "filter", value: @filter)

              div(class: "flex flex-row items-end gap-4") do
                div(class: "flex-1") do
                  label(class: "text-sm font-medium mb-1 block") { "Search by Invoice Number" }
                  render RubyUI::Input.new(
                    type: :text,
                    name: "search_query",
                    placeholder: "e.g., 9/2025",
                    value: @search_query
                  )
                end

                div(class: "flex-1") do
                  label(class: "text-sm font-medium mb-1 block") { "From Date" }
                  render RubyUI::Input.new(
                    type: :date,
                    name: "date_from",
                    class: "date-input-icon-light text-primary-foreground",
                    value: @date_from
                  )
                end

                div(class: "flex-1") do
                  label(class: "text-sm font-medium mb-1 block") { "To Date" }
                  render RubyUI::Input.new(
                    type: :date,
                    name: "date_to",
                    class: "date-input-icon-light text-primary-foreground",
                    value: @date_to
                  )
                end

                div(class: "flex gap-2") do
                  Button(variant: :primary, type: :submit) { "Search" }
                  if @search_query.present? || @date_from.present? || @date_to.present?
                    a(
                      href: view_context.invoices_path(filter: @filter),
                      data: {
                        turbo_stream: true,
                        action: "click->invoice-filter#showSpinner"
                      },
                      class: "inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors h-9 px-4 py-2 border border-input bg-background hover:bg-accent hover:text-accent-foreground"
                    ) { "Clear" }
                  end
                end
              end
            end
          end
        end
    end
  end
end
