module Views
  module Accounting
    module Invoices
        class List < ::Views::Base
          def initialize(user:, filter: "unpaid")
            @user = user
            @filter = filter
          end

          def view_template
            div(class: "flex flex-col gap-4", id: "invoices_filter_section", data: { controller: "invoice-filter" }) do
              # Filter buttons
              div(class: "flex gap-2") do
                BadgeLink(
                  href: view_context.invoices_path(filter: "unpaid"),
                  variant: :sky,
                  active: @filter == "unpaid",
                  data: {
                    turbo_stream: true,
                    action: "click->invoice-filter#showSpinner"
                  },
                  id: "filter_unpaid"
                ) { "Unpaid" }

                BadgeLink(
                  href: view_context.invoices_path(filter: "paid"),
                  variant: :lime,
                  active: @filter == "paid",
                  data: {
                    turbo_stream: true,
                    action: "click->invoice-filter#showSpinner"
                  },
                  id: "filter_paid"
                ) { "Paid" }

                BadgeLink(
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
                render ::Views::Accounting::Invoices::ListContent.new(user: @user, filter: @filter)
              end
            end
          end
        end
    end
  end
end
