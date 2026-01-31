# frozen_string_literal: true

module Views
  module ApiTokens
    class Index < ::Views::Base
      def initialize(api_tokens:)
        @api_tokens = api_tokens
      end

      def view_template
        div(class: "flex h-full flex-col max-w-3xl") do
          render_header
          render_create_form
          render_tokens_list
          render_api_instructions
        end
      end

      private

      def render_header
        div(class: "mb-6") do
          h1(class: "text-2xl font-bold") { "API Access" }
          p(class: "text-sm text-muted-foreground mt-1") do
            plain "Manage API tokens for programmatic access to your Doosr data."
          end
        end
      end

      def render_create_form
        div(class: "mb-8 p-4 bg-card border rounded-lg") do
          h2(class: "text-lg font-semibold mb-3") { "Create Token" }
          render RubyUI::Form.new(
            action: api_tokens_path,
            method: "post",
            class: "flex gap-2 items-end",
            data: {
              controller: "modal-form",
              modal_form_loading_message_value: "Creating token...",
              modal_form_success_message_value: "Token created",
              action: "turbo:submit-end->modal-form#handleSubmitEnd"
            }
          ) do
            render RubyUI::Input.new(
              type: :hidden,
              name: "authenticity_token",
              value: view_context.form_authenticity_token
            )
            render RubyUI::FormField.new do
              render RubyUI::FormFieldLabel.new(for: "token_name") { "Token Name" }
              render RubyUI::Input.new(
                type: :text,
                name: "name",
                id: "token_name",
                placeholder: "e.g. My Script, CI/CD, Shortcuts",
                required: true,
                class: "min-w-[250px]"
              )
              render RubyUI::FormFieldError.new
            end
            Button(type: "submit", variant: :primary, class: "shrink-0") { "Create Token" }
          end
          div(id: "token_form_errors", class: "mt-2")
        end
      end

      def render_tokens_list
        div(class: "mb-8") do
          h2(class: "text-lg font-semibold mb-3") { "Your Tokens" }
          div(id: "no_tokens_message") do
            if @api_tokens.empty?
              p(class: "text-sm text-muted-foreground") { "No API tokens yet. Create one to get started." }
            end
          end
          div(id: "api_tokens_list", class: "space-y-2") do
            @api_tokens.each do |api_token|
              render ::Components::ApiTokens::TokenRow.new(api_token: api_token)
            end
          end
        end
      end

      def render_api_instructions
        div(class: "p-4 bg-card border rounded-lg") do
          h2(class: "text-lg font-semibold mb-3") { "API Usage" }

          div(class: "space-y-4 text-sm") do
            render_instruction(
              "Base URL",
              "All API requests use the following base URL:",
              "#{view_context.request.base_url}/api/v1"
            )

            render_instruction(
              "Authentication",
              "Include your token in the Authorization header:",
              "Authorization: Bearer doo_your_token_here"
            )

            div do
              h3(class: "font-medium mb-1") { "Example" }
              p(class: "text-muted-foreground mb-2") { "Fetch today's day:" }
              pre(class: "bg-muted p-3 rounded-md overflow-x-auto text-xs") do
                code do
                  plain "curl -H \"Authorization: Bearer doo_your_token_here\" \\\n"
                  plain "     #{view_context.request.base_url}/api/v1/days?date=#{Date.today}"
                end
              end
            end

            div do
              h3(class: "font-medium mb-1") { "Available Endpoints" }
              div(class: "bg-muted p-3 rounded-md text-xs space-y-1 font-mono") do
                p { "GET    /api/v1/days?date=YYYY-MM-DD   # Show day" }
                p { "POST   /api/v1/days                    # Open day" }
                p { "PATCH  /api/v1/days/:id/close          # Close day" }
                p { "PATCH  /api/v1/days/:id/reopen         # Reopen day" }
                p { "POST   /api/v1/days/import             # Import items" }
              end
            end
          end
        end
      end

      def render_instruction(title, description, code_content)
        div do
          h3(class: "font-medium mb-1") { title }
          p(class: "text-muted-foreground mb-2") { description }
          pre(class: "bg-muted p-3 rounded-md overflow-x-auto text-xs") do
            code { code_content }
          end
        end
      end
    end
  end
end
