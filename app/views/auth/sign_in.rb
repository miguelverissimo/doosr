# frozen_string_literal: true

module Views
  module Auth
    class SignIn < ::Views::Base
      def initialize(resource:, resource_name:, devise_mapping:)
        @resource = resource
        @resource_name = resource_name
        @devise_mapping = devise_mapping
      end

      def view_template
        div(class: "mx-auto flex min-h-screen w-full max-w-md items-center justify-center px-4") do
          div(class: "w-full space-y-6") do
            header(class: "space-y-2 text-center") do
              h1(class: "text-2xl font-semibold tracking-tight") { "Log in to Doosr" }
              p(class: "text-sm text-muted-foreground") do
                "Use your email and password or continue with a provider."
              end
            end

            form(
              action: user_session_path,
              method: "post",
              class: "space-y-4 rounded-xl border bg-card p-6 shadow-sm",
              data: {
                turbo: "false"
              }
            ) do
              csrf_token_field

              # Error message container that Turbo Stream will update
              div(id: "auth_error") do
                if view_context.flash[:alert].present?
                  div(class: "rounded-lg border border-red-200 bg-red-50 p-3 text-sm text-red-800 dark:border-red-800 dark:bg-red-950 dark:text-red-200") do
                    div(class: "flex items-start gap-2") do
                      svg(
                        xmlns: "http://www.w3.org/2000/svg",
                        class: "h-4 w-4 flex-shrink-0 mt-0.5",
                        viewBox: "0 0 24 24",
                        fill: "none",
                        stroke: "currentColor",
                        stroke_width: "2",
                        stroke_linecap: "round",
                        stroke_linejoin: "round"
                      ) do |s|
                        s.circle(cx: "12", cy: "12", r: "10")
                        s.path(d: "m15 9-6 6M9 9l6 6")
                      end
                      span { view_context.flash[:alert] }
                    end
                  end
                end
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
                FormFieldHint { "We'll never share your email." }
              end

              FormField do
                FormFieldLabel(for: "user_password") { "Password" }
                input(
                  type: "password",
                  name: "#{@resource_name}[password]",
                  id: "user_password",
                  autocomplete: "current-password",
                  required: true,
                  class: "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50",
                  data: { action: "input->auth-form#clearError" }
                )
              end

              if @devise_mapping.rememberable?
                div(class: "flex items-center justify-between text-sm text-muted-foreground") do
                  label(class: "inline-flex items-center gap-2") do
                    input(type: "checkbox",
                          name: "#{@resource_name}[remember_me]",
                          id: "user_remember_me",
                          class: "h-4 w-4 rounded border border-input text-primary focus-visible:ring-1 focus-visible:ring-ring")
                    span { "Remember me" }
                  end

                  if @devise_mapping.recoverable?
                    Link(href: new_user_password_path) { "Forgot your password?" }
                  end
                end
              end

              Button(type: :submit, variant: :primary, size: :md, class: "w-full") do
                "Log in"
              end
            end

            div(class: "space-y-3") do
              div(class: "flex items-center gap-3 text-xs text-muted-foreground") do
                div(class: "h-px flex-1 bg-border")
                span { "or continue with" }
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
              span { "Don't have an account?" }
              span { " " }
              Link(href: new_user_registration_path) { "Sign up" }
            end
          end
        end
      end
    end
  end
end
