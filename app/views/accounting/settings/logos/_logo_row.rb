module Views
  module Accounting
    module Settings
      module Logos
        class LogoRow < ::Views::Base
          def initialize(accounting_logo:)
            @accounting_logo = accounting_logo
          end

          def view_template
            div(
              id: "accounting_logo_#{@accounting_logo.id}_div",
              class: "flex flex-col w-full cursor-pointer gap-2 rounded-md p-3 text-left bg-accent hover:bg-accent/50 transition-colors"
            ) do
              div(class: "flex flex-row items-center justify-between gap-2") do
                div(class: "text-sm font-bold mt-1") { @accounting_logo.title }
                div(class: "text-sm mt-1 text-muted-foreground") { @accounting_logo.description }
              end

              div(class: "mt-1 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2") do
                if @accounting_logo.image.attached?
                  div(
                    class: "w-full sm:w-[250px] sm:max-w-[250px] shrink-0 rounded-md border shadow-sm bg-neutral-300 p-2 flex items-center justify-center",
                    style: "background-color: rgb(212 212 212);"
                  ) do
                    img(
                      alt: "Logo",
                      loading: "lazy",
                      class: "max-w-full max-h-full object-contain",
                      style: "max-width: 100%; max-height: 100%;",
                      src: view_context.url_for(@accounting_logo.image)
                    )
                  end
                else
                  div(class: "text-sm text-gray-500") { "No image attached" }
                end

                div(class: "flex items-center gap-2 shrink-0 self-end sm:self-auto") do
                  # Edit button with dialog
                  render RubyUI::Dialog.new do
                    render RubyUI::DialogTrigger.new do
                      Button(variant: :outline, icon: true) do
                        render ::Components::Icon.new(name: :edit, size: "12", class: "w-5 h-5")
                      end
                    end
                    render_edit_dialog
                  end

                  # Delete button with AlertDialog confirmation
                  render_delete_confirmation_dialog
                end
              end
            end
          end

          def render_edit_dialog
            render RubyUI::DialogContent.new(size: :lg) do
              render RubyUI::DialogHeader.new do
                render RubyUI::DialogTitle.new { "Edit Logo" }
              end

              render RubyUI::DialogMiddle.new do
                render ::Components::Accounting::Settings::Logos::Form.new(accounting_logo: @accounting_logo)
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
                  render RubyUI::AlertDialogTitle.new { "Are you sure you want to delete #{@accounting_logo.title}?" }
                  render RubyUI::AlertDialogDescription.new { "This action cannot be undone. This will permanently delete the logo." }
                end

                render RubyUI::AlertDialogFooter.new(class: "mt-6 flex flex-row justify-end gap-3") do
                  render RubyUI::AlertDialogCancel.new { "Cancel" }

                  form(
                    action: view_context.settings_logo_path(@accounting_logo),
                    method: "post",
                    data: {
                      turbo_method: :delete,
                      action: "submit@document->ruby-ui--alert-dialog#dismiss"
                    },
                    class: "inline",
                    id: "delete_logo_#{@accounting_logo.id}"
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
