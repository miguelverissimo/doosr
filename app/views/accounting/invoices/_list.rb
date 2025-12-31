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
              # Turbo frame for lazy-loaded dialogs
              turbo_frame_tag "invoice_dialog"

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
            # Just render the button - form will load lazily
            a(
              href: view_context.new_invoice_path,
              data: { turbo_frame: "invoice_dialog" },
              class: "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:size-4 [&_svg]:shrink-0 shadow bg-primary text-primary-foreground hover:bg-primary/90 h-9 px-4 py-2"
            ) { "Add Invoice" }
          end

          def render_invoice_from_template_dialog
            # Just render the button - form will load lazily
            a(
              href: view_context.new_from_template_invoices_path,
              data: { turbo_frame: "invoice_dialog" },
              class: "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:size-4 [&_svg]:shrink-0 shadow border border-input bg-background hover:bg-accent hover:text-accent-foreground h-9 px-4 py-2"
            ) { "From Template" }
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
