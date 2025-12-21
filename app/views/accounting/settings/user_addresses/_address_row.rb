module Views
  module Accounting
    module Settings
      module UserAddresses
        class AddressRow < Views::Base
          def initialize(address:)
            @address = address
          end

          def view_template
            div(
              id: "address_#{@address.id}",
              class: address_classes

            ) do
              # Row 1: name on the left, badge on the right
              div(class: "flex flex-row items-center justify-between gap-2") do
                div(class: "text-sm font-bold mt-1") { @address.name }
                if @address.active?
                  Badge(variant: :lime) { @address.state.to_s }
                else
                  Badge(variant: :indigo) { @address.state.to_s }
                end
              end

              # Row 2: left = address+country, right = buttons
              div(class: "mt-1 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2") do
                # Left column: address (full) + country
                div(class: "flex-1 min-w-0 space-y-1") do
                  div(class: "text-sm") do
                    @address.full_address.to_s.split("\n").each_with_index do |line, index|
                      span { line }
                      br if index < @address.full_address.to_s.split("\n").length - 1
                    end
                  end
                  div(class: "text-sm font-bold mt-1") { @address.country.upcase }
                end

                # Right column: buttons
                div(class: "flex items-center gap-2 shrink-0 self-end sm:self-auto") do
                  # Edit button with dialog
                  render RubyUI::Dialog.new do
                    render RubyUI::DialogTrigger.new do
                      Button(variant: :outline, icon: true) do
                        render Components::Icon.new(name: :edit, size: "12", class: "w-5 h-5")
                      end
                    end
                    render_edit_dialog
                  end

                  # Make active button (toggle state)
                  form(
                    action: view_context.activate_settings_address_path(@address),
                    method: "post",
                    data: {
                      turbo_method: :patch,
                      turbo: true
                    },
                    class: "inline"
                  ) do
                    input(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)
                    input(type: :hidden, name: "_method", value: "patch")
                    Button(variant: :secondary, icon: true, type: "submit") do
                      render Components::Icon.new(name: :check, size: "12", class: "w-5 h-5")
                    end
                  end

                  # Delete button with AlertDialog confirmation
                  render_delete_confirmation_dialog
                end
              end
            end
          end

          def address_classes
            base_classes = "flex flex-col w-full cursor-pointer gap-2 rounded-md p-3 text-left transition-colors"
            case @address.state.to_sym
            when :active
              "#{base_classes} bg-accent hover:bg-accent/50"
            when :inactive
              "#{base_classes} bg-muted hover:bg-muted/50"
            end
          end

          def render_edit_dialog
            render RubyUI::DialogContent.new(size: :lg) do
              render RubyUI::DialogHeader.new do
                render RubyUI::DialogTitle.new { "Edit Address" }
                render RubyUI::DialogDescription.new { "Update the address information" }
              end

              render RubyUI::DialogMiddle.new do
                render Components::Accounting::Settings::Addresses::Form.new(address: @address)
              end
            end
          end

          def render_delete_confirmation_dialog
            render RubyUI::AlertDialog.new do
              render RubyUI::AlertDialogTrigger.new do
                Button(variant: :destructive, icon: true) do
                  render Components::Icon.new(name: :delete, size: "12", class: "w-5 h-5")
                end
              end
              
              render RubyUI::AlertDialogContent.new do
                render RubyUI::AlertDialogHeader.new do
                  render RubyUI::AlertDialogTitle.new { "Are you sure you want to delete #{@address.name}?" }
                  render RubyUI::AlertDialogDescription.new { "This action cannot be undone. This will permanently delete the address." }
                end
                
                # Footer actions: single horizontal row, right aligned
                render RubyUI::AlertDialogFooter.new(class: "mt-6 flex flex-row justify-end gap-3") do
                  render RubyUI::AlertDialogCancel.new { "Cancel" }

                  # Form for delete action
                  form(
                    action: view_context.settings_address_path(@address),
                    method: "post",
                    data: { 
                      turbo_method: :delete,
                      action: "submit@document->ruby-ui--alert-dialog#dismiss"
                    },
                    class: "inline",
                    id: "delete_address_#{@address.id}"
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
end