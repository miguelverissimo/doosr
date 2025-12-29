# frozen_string_literal: true

module Views
  module Auth
    class SignUp < ::Views::Base
      def initialize(resource:, resource_name:, minimum_password_length:)
        @resource = resource
        @resource_name = resource_name
        @minimum_password_length = minimum_password_length
      end

      def view_template
        div(class: "mx-auto flex min-h-screen w-full max-w-md items-center justify-center px-4") do
          div(class: "w-full space-y-6") do
            header(class: "space-y-2 text-center") do
              h1(class: "text-2xl font-semibold tracking-tight") { "Create your Doosr account" }
              p(class: "text-sm text-muted-foreground") do
                "Get started in a few seconds. No credit card required."
              end
            end

            form(
              action: user_registration_path,
              method: "post",
              class: "space-y-4 rounded-xl border bg-card p-6 shadow-sm",
              data: {
                controller: "auth-form",
                action: "turbo:submit-start->auth-form#showLoading turbo:submit-end->auth-form#hideLoading"
              }
            ) do
              csrf_token_field

              # Error message container that Turbo Stream will update
              div(id: "auth_error") do
                if @resource&.errors&.any?
                  div(class: "rounded-lg border border-red-200 bg-red-50 p-3 text-sm text-red-800 dark:border-red-800 dark:bg-red-950 dark:text-red-200") do
                    ul(class: "list-disc space-y-1 pl-5") do
                      @resource.errors.full_messages.each do |msg|
                        li { msg }
                      end
                    end
                  end
                end
              end

              FormField do
                FormFieldLabel(for: "user_name") { "Name" }
                input(
                  type: "text",
                  name: "#{@resource_name}[name]",
                  id: "user_name",
                  required: true,
                  autocomplete: "name",
                  class: "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50",
                  data: { action: "input->auth-form#clearError" }
                )
              end

              FormField do
                FormFieldLabel(for: "user_email") { "Email" }
                input(
                  type: "email",
                  name: "#{@resource_name}[email]",
                  id: "user_email",
                  required: true,
                  autocomplete: "email",
                  class: "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50",
                  data: { action: "input->auth-form#clearError" }
                )
              end

              FormField do
                FormFieldLabel(for: "user_password") { "Password" }
                if @minimum_password_length
                  FormFieldHint do
                    "#{@minimum_password_length} characters minimum"
                  end
                end
                input(
                  type: "password",
                  name: "#{@resource_name}[password]",
                  id: "user_password",
                  required: true,
                  autocomplete: "new-password",
                  class: "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50",
                  data: { action: "input->auth-form#clearError" }
                )
              end

              FormField do
                FormFieldLabel(for: "user_password_confirmation") { "Confirm password" }
                input(
                  type: "password",
                  name: "#{@resource_name}[password_confirmation]",
                  id: "user_password_confirmation",
                  required: true,
                  autocomplete: "new-password",
                  class: "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50",
                  data: { action: "input->auth-form#clearError" }
                )
              end

              Button(type: :submit, variant: :primary, size: :md, class: "w-full") do
                "Create account"
              end
            end

            div(class: "space-y-3") do
              div(class: "flex items-center gap-3 text-xs text-muted-foreground") do
                div(class: "h-px flex-1 bg-border")
                span { "or sign up with" }
                div(class: "h-px flex-1 bg-border")
              end

              div(class: "grid grid-cols-1 gap-3") do
                Link(href: user_google_oauth2_omniauth_authorize_path,
                     variant: :outline,
                     class: "w-full justify-center gap-2") do
                  span { "Continue with Google" }
                end

                Link(href: user_github_omniauth_authorize_path,
                     variant: :outline,
                     class: "w-full justify-center gap-2") do
                  span { "Continue with GitHub" }
                end
              end
            end

            div(class: "text-center text-sm text-muted-foreground") do
              span { "Already have an account?" }
              span { " " }
              Link(href: new_user_session_path) { "Log in" }
            end
          end
        end
      end
    end
  end
end


