# frozen_string_literal: true

module Components
  module ApiTokens
    class TokenCreatedDialog < ::Components::Base
      def initialize(plain_token:, token_name:)
        @plain_token = plain_token
        @token_name = token_name
      end

      def view_template
        render RubyUI::Dialog.new(open: true) do
          render RubyUI::DialogContent.new do
            render RubyUI::DialogHeader.new do
              render RubyUI::DialogTitle.new { "Token Created" }
              render RubyUI::DialogDescription.new do
                plain "Your API token has been created. Copy it now — it won't be shown again."
              end
            end

            render RubyUI::DialogMiddle.new do
              div(class: "space-y-4") do
                div do
                  p(class: "text-sm font-medium mb-1") { @token_name }
                  render RubyUI::Clipboard.new(
                    success: "Token copied to clipboard",
                    class: "[&>div:first-child]:flex [&>div:first-child]:items-center [&>div:first-child]:gap-2"
                  ) do
                    render RubyUI::ClipboardSource.new do
                      render RubyUI::Input.new(
                        type: :text,
                        value: @plain_token,
                        readonly: true,
                        class: "font-mono text-xs"
                      )
                    end
                    render RubyUI::ClipboardTrigger.new do
                      Button(variant: :outline, size: :sm, class: "shrink-0") do
                        render ::Components::Icon::Copy.new(size: "16")
                      end
                    end
                  end
                end

                div(class: "p-3 bg-amber-50 dark:bg-amber-950 border border-amber-200 dark:border-amber-800 rounded-md") do
                  p(class: "text-sm text-amber-800 dark:text-amber-200") do
                    strong { "Important: " }
                    plain "This token will not be shown again. Store it securely."
                  end
                end
              end
            end

            render RubyUI::DialogFooter.new do
              Button(
                variant: :primary,
                data: { action: "click->modal-form#cancelDialog" }
              ) { "Done" }
            end
          end
        end
      end
    end
  end
end
