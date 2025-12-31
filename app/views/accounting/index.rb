module Views
  module Accounting
    class Index < ::Views::Base
      def initialize
      end

      def view_template
        div(class: "flex h-full flex-col") do
          tabs_data = [
            { value: "invoicing", label: "Invoicing" },
            { value: "receipts", label: "Receipts" },
            { value: "customers", label: "Customers" },
            { value: "items", label: "Items" },
            { value: "automations", label: "Automations" },
            { value: "settings", label: "Settings" }
          ]

          Tabs(default_value: "invoicing") do
            render RubyUI::ResponsiveTabsList.new(
              tabs: tabs_data,
              current_value: "invoicing"
            )
            TabsContent(value: "invoicing") do
              div(class: "rounded-lg border p-6 space-y-4 bg-background text-foreground") do
                render ::Views::Accounting::Invoices::Index.new
              end
            end
            TabsContent(value: "receipts", data: { controller: "lazy-tab" }) do
              div(class: "rounded-lg border p-6 space-y-4 bg-background text-foreground") do
                turbo_frame_tag "receipts_index_content", loading: "lazy", data: { lazy_tab_target: "frame", src: view_context.receipts_path } do
                  render ::Components::Shared::LoadingSpinner.new(message: "Loading receipts...")
                end
              end
            end
            TabsContent(value: "customers", data: { controller: "lazy-tab" }) do
              div(class: "rounded-lg border p-6 space-y-4 bg-background text-foreground") do
                turbo_frame_tag "customers_tab_content", loading: "lazy", data: { lazy_tab_target: "frame", src: view_context.customers_tab_accounting_index_path } do
                  render ::Components::Shared::LoadingSpinner.new(message: "Loading customers...")
                end
              end
            end
            TabsContent(value: "items", data: { controller: "lazy-tab" }) do
              div(class: "rounded-lg border p-6 space-y-4 bg-background text-foreground") do
                turbo_frame_tag "accounting_items_tab_content", loading: "lazy", data: { lazy_tab_target: "frame", src: view_context.accounting_items_tab_accounting_index_path } do
                  render ::Components::Shared::LoadingSpinner.new(message: "Loading items...")
                end
              end
            end
            TabsContent(value: "automations") do
              div(class: "rounded-lg border p-6 space-y-4 bg-background text-foreground") do
                plain "Automations"
              end
            end
            TabsContent(value: "settings", data: { controller: "lazy-tab" }) do
              div(class: "rounded-lg border p-6 space-y-4 bg-background text-foreground") do
                turbo_frame_tag "settings_tab_content", loading: "lazy", data: { lazy_tab_target: "frame", src: view_context.settings_tab_accounting_index_path } do
                  render ::Components::Shared::LoadingSpinner.new(message: "Loading settings...")
                end
              end
            end
          end
        end
      end
    end
  end
end
