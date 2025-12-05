# frozen_string_literal: true

class Components::AppSidebar < Components::Base
  def initialize(pathname: "/", **attrs)
    @pathname = pathname
    super(**attrs)
  end

  def view_template
    # Render sidebar without attrs since we don't pass any
    Sidebar(variant: :inset, collapsible: :icon) do
      SidebarHeader(class: "h-16 border-sidebar-border border-b") do
        SidebarMenu do
          SidebarMenuItem do
            SidebarMenuButton(as: :a, href: "#", size: :lg) do
              div(class: "h-8 w-8 rounded-lg bg-slate-200")
              div(class: "grid flex-1 text-left text-sm leading-tight") do
                user = view_context.current_user
                span(class: "truncate font-semibold") { user&.email&.split("@")&.first || "User" }
                span(class: "truncate text-xs") { user&.email || "user@example.com" }
              end
            end
          end
        end
      end

      SidebarContent do
        is_well_page = @pathname == "/well"
        is_lists_page = @pathname.start_with?("/lists")

        if is_well_page || is_lists_page
          SidebarMenu(class: "mt-4") do
            SidebarMenuItem do
              SidebarMenuButton(as: :a, href: authenticated_root_path) do
                span(class: "mr-2 h-4 w-4 rounded bg-slate-900/10")
                span { "Today" }
              end
            end
          end
        else
          # DatePicker would go here - for now just empty
          div(class: "mt-4")
        end

        SidebarMenu(class: "mt-4") do
          SidebarMenuItem do
            SidebarMenuButton(as: :a, href: "#") do
              span(class: "mr-2 h-4 w-4 rounded bg-slate-900/10")
              span { "The Well" }
            end
          end
          SidebarMenuItem do
            SidebarMenuButton(as: :a, href: "#") do
              span(class: "mr-2 h-4 w-4 rounded bg-slate-900/10")
              span { "Lists" }
            end
          end
        end
      end

      SidebarFooter()
      SidebarRail()
    end
  end
end

