# frozen_string_literal: true

module Views
  module Admin
    module Dashboard
      class Index < ::Views::Base
        def view_template
          div(class: "container mx-auto p-6 max-w-4xl") do
            # Header
            div(class: "mb-8") do
              h1(class: "text-3xl font-bold") { "Admin Dashboard" }
              p(class: "text-muted-foreground mt-2") { "Manage users and system settings" }
            end

            # Navigation Cards
            div(class: "grid grid-cols-1 md:grid-cols-2 gap-6") do
              # Users Management Card
              render_nav_card(
                title: "User Management",
                description: "Manage user access and roles",
                icon: "users",
                href: admin_users_path
              )

              # Notifications Card
              render_nav_card(
                title: "Notifications",
                description: "Manage push notifications and test delivery",
                icon: "bell",
                href: admin_notifications_path
              )
            end
          end
        end

        private

        def render_nav_card(title:, description:, icon:, href:)
          a(
            href: href,
            class: "block p-6 rounded-lg border border-border bg-card hover:bg-accent transition-colors"
          ) do
            div(class: "flex items-start gap-4") do
              # Icon placeholder (you can add actual icons later)
              div(class: "flex-shrink-0 w-12 h-12 rounded-lg bg-primary/10 flex items-center justify-center") do
                span(class: "text-2xl") { icon == "users" ? "👥" : "🔔" }
              end

              div(class: "flex-1") do
                h2(class: "text-xl font-semibold mb-2") { title }
                p(class: "text-muted-foreground text-sm") { description }
              end

              # Arrow icon
              div(class: "flex-shrink-0") do
                span(class: "text-muted-foreground") { "→" }
              end
            end
          end
        end
      end
    end
  end
end
