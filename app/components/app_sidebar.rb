# frozen_string_literal: true

class Components::AppSidebar < Components::Base
  def initialize(pathname: "/", selected_date: nil, **attrs)
    @pathname = pathname
    @selected_date = selected_date
    super(**attrs)
  end

  def view_template
    # Render sidebar without attrs since we don't pass any
    Sidebar(variant: :inset, collapsible: :icon) do
      SidebarHeader(class: "h-16 border-sidebar-border border-b") do
        SidebarMenu do
          SidebarMenuItem do
            SidebarMenuButton(as: :a, href: "#", size: :lg) do
              user = view_context.current_user

              div(class: "flex h-8 w-8 items-center justify-center rounded-lg bg-sidebar-primary text-sidebar-primary-foreground shrink-0") do
                span(class: "text-sm font-semibold") { (user&.email&.first || "U").upcase }
              end
              div(class: "grid flex-1 text-left text-sm leading-tight group-data-[collapsible=icon]:hidden") do
                span(class: "truncate font-semibold") { user&.email&.split("@")&.first || "User" }
                span(class: "truncate text-xs") { user&.email || "user@example.com" }
              end
            end
          end
        end
      end

      SidebarContent do
        is_day_view = @pathname == "/" || @pathname.start_with?("/day")
        is_well_page = @pathname == "/well"
        is_lists_page = @pathname.start_with?("/lists")

        if is_day_view
          # Show calendar for day view
          render_day_calendar
        elsif is_well_page || is_lists_page
          SidebarMenu(class: "mt-4") do
            SidebarMenuItem do
              SidebarMenuButton(as: :a, href: authenticated_root_path) do
                render_icon(:calendar)
                span(class: "group-data-[collapsible=icon]:hidden") { "Today" }
              end
            end
          end
        else
          div(class: "mt-4")
        end

        SidebarMenu(class: "mt-4") do
          SidebarMenuItem do
            SidebarMenuButton(as: :a, href: "#") do
              render_icon(:droplet)
              span(class: "group-data-[collapsible=icon]:hidden") { "The Well" }
            end
          end
          SidebarMenuItem do
            SidebarMenuButton(as: :a, href: "#") do
              render_icon(:list)
              span(class: "group-data-[collapsible=icon]:hidden") { "Lists" }
            end
          end
        end
      end

      SidebarFooter()
      SidebarRail()
    end
  end

  private

  def render_day_calendar
    div(
      class: "px-2 pb-3 group-data-[collapsible=icon]:hidden",
      data: {
        controller: "day-calendar"
      }
    ) do
      Calendar(
        selected_date: @selected_date,
        class: "!p-2 !space-y-2 rounded-md border shadow-sm text-sm"
      )

      # Today button below calendar
      div(class: "mt-2") do
        a(
          href: day_path(date: Date.today.to_s),
          class: "inline-flex items-center justify-center w-full gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 border border-input bg-background shadow-sm hover:bg-accent hover:text-accent-foreground h-9 px-4 py-2"
        ) do
          render_icon(:calendar)
          span { "Today" }
        end
      end
    end
  end

  def render_icon(name)
    case name
    when :calendar
      svg(
        xmlns: "http://www.w3.org/2000/svg",
        width: "16",
        height: "16",
        viewBox: "0 0 24 24",
        fill: "none",
        stroke: "currentColor",
        stroke_width: "2",
        stroke_linecap: "round",
        stroke_linejoin: "round",
        class: "shrink-0"
      ) do |s|
        s.path(d: "M8 2v4")
        s.path(d: "M16 2v4")
        s.rect(width: "18", height: "18", x: "3", y: "4", rx: "2")
        s.path(d: "M3 10h18")
      end
    when :droplet
      svg(
        xmlns: "http://www.w3.org/2000/svg",
        width: "16",
        height: "16",
        viewBox: "0 0 24 24",
        fill: "none",
        stroke: "currentColor",
        stroke_width: "2",
        stroke_linecap: "round",
        stroke_linejoin: "round",
        class: "shrink-0"
      ) do |s|
        s.path(d: "M12 22a7 7 0 0 0 7-7c0-2-1-3.9-3-5.5s-3.5-4-4-6.5c-.5 2.5-2 4.9-4 6.5C6 11.1 5 13 5 15a7 7 0 0 0 7 7z")
      end
    when :list
      svg(
        xmlns: "http://www.w3.org/2000/svg",
        width: "16",
        height: "16",
        viewBox: "0 0 24 24",
        fill: "none",
        stroke: "currentColor",
        stroke_width: "2",
        stroke_linecap: "round",
        stroke_linejoin: "round",
        class: "shrink-0"
      ) do |s|
        s.line(x1: "8", x2: "21", y1: "6", y2: "6")
        s.line(x1: "8", x2: "21", y1: "12", y2: "12")
        s.line(x1: "8", x2: "21", y1: "18", y2: "18")
        s.line(x1: "3", x2: "3.01", y1: "6", y2: "6")
        s.line(x1: "3", x2: "3.01", y1: "12", y2: "12")
        s.line(x1: "3", x2: "3.01", y1: "18", y2: "18")
      end
    end
  end
end

