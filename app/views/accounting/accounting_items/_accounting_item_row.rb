module Views
  module Accounting
    module AccountingItems
      class AccountingItemRow < Views::Base
        include Phlex::Rails::Helpers::NumberToCurrency

        def initialize(accounting_item:)
          @accounting_item = accounting_item
        end

        def view_template
          div(
            id: "accounting_item_#{@accounting_item.id}_div", 
            class: "flex flex-col w-full gap-2 rounded-md p-3 text-left transition-colors border border-border bg-muted hover:bg-muted/50"
          ) do
            div(class: "flex flex-row items-center justify-between gap-2") do
              div(class: "text-md font-bold mt-1") { @accounting_item.name }
              div(class: "text-sm mt-1") { @accounting_item.reference }
            end

            div(class: "flex flex-row items-center justify-between gap-2") do
              render_monetary_info(@accounting_item)
            end
            div(class: "flex flex-row items-center justify-between gap-2") do
              div(class: "flex gap-2 justify-start") do
                render_badge(@accounting_item)

                div(class: "flex flex-row items-center gap-2") do
                  if @accounting_item.convert_currency
                    span(class: "text-lime-500") { render_icon(:convert_currency) }
                  else
                    span(class: "text-red-500") { render_icon(:no_currency_conversion) }
                  end
                end
              end
              
              div(class: "flex gap-2 justify-end") do
                render RubyUI::Dialog.new do
                  render RubyUI::DialogTrigger.new do
                    Button(variant: :outline, icon: true) do
                      render_icon(:edit)
                    end
                  end
                  render_edit_dialog
                end

                render_delete_confirmation_dialog
              end
            end
          end
        end

        def render_edit_dialog
          render RubyUI::DialogContent.new(size: :lg) do
            render RubyUI::DialogHeader.new do
              render RubyUI::DialogTitle.new { "Edit Accounting Item" }
              render RubyUI::DialogDescription.new { "Update the accounting item information" }
            end

            render RubyUI::DialogMiddle.new do
              render Components::Accounting::AccountingItems::Form.new(accounting_item: @accounting_item)
            end
          end
        end

        def render_delete_confirmation_dialog
          render RubyUI::AlertDialog.new do
            render RubyUI::AlertDialogTrigger.new do
              Button(variant: :destructive, icon: true) do
                render_icon(:delete)
              end
            end
            
            render RubyUI::AlertDialogContent.new do
              render RubyUI::AlertDialogHeader.new do
                render RubyUI::AlertDialogTitle.new { "Are you sure you want to delete #{@accounting_item.name}?" }
                render RubyUI::AlertDialogDescription.new { "This action cannot be undone. This will permanently delete the accounting item." }
              end
              
              # Footer actions: single horizontal row, right aligned
              render RubyUI::AlertDialogFooter.new(class: "mt-6 flex flex-row justify-end gap-3") do
                render RubyUI::AlertDialogCancel.new { "Cancel" }

                # Form for delete action
                form(
                  action: view_context.accounting_item_path(@accounting_item),
                  method: "post",
                  data: { 
                    turbo_method: :delete,
                    action: "submit@document->ruby-ui--alert-dialog#dismiss"
                  },
                  class: "inline",
                  id: "delete_accounting_item_#{@accounting_item.id}"
                ) do
                  input(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)
                  input(type: :hidden, name: "_method", value: "delete")
                  render RubyUI::AlertDialogAction.new(type: "submit", variant: :destructive) { "Delete" }
                end
              end
            end
          end
        end

        def render_monetary_info(accounting_item)
          div(class: "text-md mt-1") do
            plain "#{accounting_item.currency} "
            plain number_to_currency(accounting_item.price / 100.0)
            plain " / #{accounting_item.unit} "
            span(class: "text-sm") do
              plain "that "
              if accounting_item.convert_currency
                span(class: "font-bold text-lime-500") { "will" }
              else
                span(class: "font-bold text-red-500") { "will not" }
              end
              plain " be converted to the invoice currency on issuance."
            end
          end
        end

        def render_badge(accounting_item)
          case accounting_item.kind
          when "service"
            Badge(variant: :lime) { "Service" }
          when "product"
            Badge(variant: :amber) { "Product" }
          when "tool"
            Badge(variant: :teal) { "Tool" }
          when "goods"
            Badge(variant: :purple) { "Goods" }
          when "equipment"
            Badge(variant: :indigo) { "Equipment" }
          when "other"
            Badge(variant: :rose) { "Other" }
          end
        end

        def render_icon(name)
          case name
          when :edit
            svg(
              xmlns: "http://www.w3.org/2000/svg",
              width: "12",
              height: "12",
              viewBox: "0 0 24 24",
              fill: "none",
              stroke: "currentColor",
              stroke_width: "2",
              stroke_linecap: "round",
              stroke_linejoin: "round",
              class: "w-5 h-5"
            ) do |s|
              s.path(d: "M12 20h9")
              s.path(d: "M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4L16.5 3.5z")
            end
          when :delete
            svg(
              xmlns: "http://www.w3.org/2000/svg",
              width: "12",
              height: "12",
              viewBox: "0 0 24 24",
              fill: "none",
              stroke: "currentColor",
              stroke_width: "2",
              stroke_linecap: "round",
              stroke_linejoin: "round",
              class: "w-5 h-5"
            ) do |s|
              s.path(d: "M3 6h18")
              s.path(d: "M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2")
            end
          when :convert_currency
            svg(
              xmlns: "http://www.w3.org/2000/svg",
              width: "12",
              height: "12",
              viewBox: "0 0 24 24",
              fill: "none",
              stroke: "currentColor",
              stroke_width: "2",
              stroke_linecap: "round",
              stroke_linejoin: "round",
              class: "w-5 h-5"
            ) do |s|
              s.path(d: "M12 18H4a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5")
              s.path(d: "M18 12h.01")
              s.path(d: "M19 22v-6")
              s.path(d: "m22 19-3-3-3 3")
              s.path(d: "M6 12h.01")
              s.circle(cx: "12", cy: "12", r: "2")
            end
          when :no_currency_conversion
            svg(
              xmlns: "http://www.w3.org/2000/svg",
              width: "12",
              height: "12",
              viewBox: "0 0 24 24",
              fill: "none",
              stroke: "currentColor",
              stroke_width: "2",
              stroke_linecap: "round",
              stroke_linejoin: "round",
              class: "w-5 h-5"
            ) do |s|
              s.path(d: "M13 18H4a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5")
              s.path(d: "m17 17 5 5")
              s.path(d: "M18 12h.01")
              s.path(d: "m22 17-5 5")
              s.path(d: "M6 12h.01")
              s.circle(cx: "12", cy: "12", r: "2")
            end
          end
        end
      end
    end
  end
end