# frozen_string_literal: true

module Views
  module Auth
    class SignIn < Views::Base
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

            Form(action: helpers.session_path(@resource_name), method: "post", class: "space-y-4 rounded-xl border bg-card p-6 shadow-sm") do
              csrf_token_field

              FormField do
                FormFieldLabel(for: "user_email") { "Email" }
                Input(type: :email,
                      name: "#{@resource_name}[email]",
                      id: "user_email",
                      required: true,
                      autocomplete: "email")
                FormFieldHint { "We'll never share your email." }
              end

              FormField do
                FormFieldLabel(for: "user_password") { "Password" }
                Input(type: :password,
                      name: "#{@resource_name}[password]",
                      id: "user_password",
                      autocomplete: "current-password",
                      required: true)
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
                    Link(href: helpers.new_password_path(@resource_name)) { "Forgot your password?" }
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
                Link(href: helpers.user_google_oauth2_omniauth_authorize_path,
                     variant: :outline,
                     class: "w-full justify-center gap-2") do
                  span { "Continue with Google" }
                end

                Link(href: helpers.user_github_omniauth_authorize_path,
                     variant: :outline,
                     class: "w-full justify-center gap-2") do
                  span { "Continue with GitHub" }
                end
              end
            end

            div(class: "text-center text-sm text-muted-foreground") do
              span { "Don't have an account?" }
              span { " " }
              Link(href: helpers.new_user_registration_path) { "Sign up" }
            end
          end
        end
      end
    end
  end
end


