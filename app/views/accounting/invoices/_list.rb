module Views
  module Accounting
    module Invoices
        class List < ::Views::Base
          def initialize(user:)
            @user = user
          end

          def view_template
            div(class: "flex flex-col gap-4") do
              # Filter buttons
              div(class: "flex gap-2") do
                a(
                  href: view_context.invoices_path(filter: "unpaid"),
                  data: {
                    turbo_frame: "invoices_content",
                    turbo_prefetch: "false",
                    action: "click->invoice-filter#setActive"
                  },
                  class: "cursor-pointer",
                  id: "filter_unpaid"
                ) do
                  Badge(variant: :sky) { "Unpaid" }
                end

                a(
                  href: view_context.invoices_path(filter: "paid"),
                  data: {
                    turbo_frame: "invoices_content",
                    turbo_prefetch: "false",
                    action: "click->invoice-filter#setActive"
                  },
                  class: "cursor-pointer",
                  id: "filter_paid"
                ) do
                  Badge(variant: :lime) { "Paid" }
                end

                a(
                  href: view_context.invoices_path(filter: "all"),
                  data: {
                    turbo_frame: "invoices_content",
                    turbo_prefetch: "false",
                    action: "click->invoice-filter#setActive"
                  },
                  class: "cursor-pointer",
                  id: "filter_all"
                ) do
                  Badge(variant: :rose) { "All" }
                end
              end

              # Container for Turbo Stream updates
              div(id: "invoices_list", data: { controller: "invoice-filter" }) do
                # Pre-rendered loading spinner (hidden by default, shown via JS)
                div(
                  id: "invoices_loading_spinner",
                  class: "hidden",
                  data: { invoice_filter_target: "spinner" }
                ) do
                  render ::Components::Shared::LoadingSpinner.new(message: "Loading invoices...")
                end

                turbo_frame_tag "invoices_content", data: { lazy_tab_target: "frame", src: view_context.invoices_path(filter: "unpaid"), invoice_filter_target: "frame" } do
                  render ::Components::Shared::LoadingSpinner.new(message: "Loading invoices...")
                end
              end
            end
          end
        end
    end
  end
end