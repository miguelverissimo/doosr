module Components
  module Accounting
    module Settings
      module Logos
        class Form < ::Components::Base
          def initialize(accounting_logo: nil, **attrs)
            @accounting_logo = accounting_logo || ::Accounting::AccountingLogo.new
            @is_new_record = @accounting_logo.new_record?
            @action = @is_new_record ? "Create" : "Update"
            super(**attrs)
          end

          def view_template
            form_url = if @is_new_record
              view_context.settings_logos_path
            else
              view_context.settings_logo_path(@accounting_logo)
            end

            render RubyUI::Form.new(
              action: form_url,
              method: "post",
              class: "space-y-6",
              enctype: "multipart/form-data",
              data: {
                turbo: true,
                action: "turbo:submit-end@document->ruby-ui--dialog#dismiss"
              }
            ) do
              # Hidden fields for Rails
              input(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)
              input(type: :hidden, name: "_method", value: "patch") unless @is_new_record

              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new { "Title" }
                render RubyUI::Input.new(
                  type: :text,
                  name: "accounting_logo[title]",
                  placeholder: "Enter title",
                  value: @accounting_logo.title.to_s,
                  required: true
                )
                render RubyUI::FormFieldError.new
              end

              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new { "Description" }
                render RubyUI::Textarea.new(
                  name: "accounting_logo[description]",
                  placeholder: "Enter description",
                  rows: 5,
                  required: true
                ) do
                  @accounting_logo.description.to_s
                end
                render RubyUI::FormFieldError.new
              end

              render RubyUI::FormField.new do
                render RubyUI::FormFieldLabel.new { "Image" }
                render RubyUI::Input.new(
                  type: :file,
                  name: "accounting_logo[image]",
                  accept: "image/*",
                  required: @is_new_record
                )
                if @accounting_logo.image.attached?
                  AspectRatio(aspect_ratio: "16/9", class: "rounded-md overflow-hidden border shadow-sm") do
                    img(
                      src: view_context.url_for(@accounting_logo.image),
                      alt: "Logo",
                      loading: "lazy",
                      class: "w-full h-auto"
                    )
                  end
                else
                  div(class: "text-sm text-gray-500") { "No image attached" }
                end
                render RubyUI::FormFieldError.new
              end

              div(class: "flex gap-2 justify-end") do
                Button(variant: :outline, type: "button", data: { action: "click->ruby-ui--dialog#dismiss" }) { "Cancel" }
                Button(variant: :primary, type: "submit") { @action }
              end
            end
          end
        end
      end
    end
  end
end
