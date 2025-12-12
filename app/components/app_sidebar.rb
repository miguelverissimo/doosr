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
            if view_context.user_signed_in?
              render_user_menu
            else
              render_sign_in_button
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
            SidebarMenuButton(as: :a, href: view_context.lists_path) do
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

  def render_user_menu
    user = view_context.current_user

    # Don't render user menu if not authenticated
    return unless user

    # Wrap everything in a dialog controller
    render RubyUI::Dialog.new do
      render RubyUI::DropdownMenu.new do
        render RubyUI::DropdownMenuTrigger.new do
          SidebarMenuButton(as: :div, size: :lg, class: "cursor-pointer") do
            div(class: "flex h-8 w-8 items-center justify-center rounded-lg bg-sidebar-primary text-sidebar-primary-foreground shrink-0") do
              span(class: "text-sm font-semibold") { (user&.email&.first || "U").upcase }
            end
            div(class: "grid flex-1 text-left text-sm leading-tight group-data-[collapsible=icon]:hidden") do
              span(class: "truncate font-semibold") { user&.email&.split("@")&.first || "User" }
              span(class: "truncate text-xs") { user&.email || "user@example.com" }
            end
          end
        end

        render RubyUI::DropdownMenuContent.new do
          render RubyUI::DialogTrigger.new do
            div(
              class: "relative flex cursor-pointer select-none items-center rounded-sm px-2 py-1.5 text-sm outline-none transition-colors hover:bg-accent hover:text-accent-foreground focus:bg-accent focus:text-accent-foreground",
              role: "menuitem"
            ) do
              render_icon(:settings)
              span(class: "ml-2") { "Settings" }
            end
          end

          render RubyUI::DropdownMenuItem.new(href: "#") do
            render_icon(:user)
            span(class: "ml-2") { "Edit Profile" }
          end

          render RubyUI::DropdownMenuSeparator.new

          render RubyUI::DropdownMenuItem.new(href: view_context.destroy_user_session_path, data: { turbo_method: :delete }) do
            render_icon(:log_out)
            span(class: "ml-2 text-destructive") { "Log out" }
          end
        end
      end

      # Settings dialog content
      render_settings_dialog
    end
  end

  def render_settings_dialog
    user = view_context.current_user

    render RubyUI::DialogContent.new(size: :lg) do
      render RubyUI::DialogHeader.new do
        render RubyUI::DialogTitle.new { "Permanent Sections" }
        render RubyUI::DialogDescription.new do
          plain "Configure permanent sections that will automatically appear in every new day."
        end
      end

      render RubyUI::DialogMiddle.new do
        # Add New Section form
        div(class: "space-y-4") do
          div(id: "add_section_form") do
            label(class: "text-sm font-medium mb-2 block") { "Add New Section" }
            form(
              action: view_context.add_section_settings_path,
              method: "post",
              class: "flex gap-2"
            ) do
              view_context.hidden_field_tag :authenticity_token, view_context.form_authenticity_token

              input(
                type: "text",
                name: "section_name",
                placeholder: "Enter section name (e.g., Work, Personal)",
                class: "flex-1 rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2",
                required: true
              )

              button(
                type: "submit",
                class: "inline-flex items-center justify-center rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 bg-primary text-primary-foreground hover:bg-primary/90 h-10 px-4 py-2 shrink-0"
              ) { "Add" }
            end
          end

          # Your Sections list
          div do
            label(class: "text-sm font-medium mb-2 block") { "Your Sections" }
            div(id: "permanent_sections_list") do
              render Components::Settings::SectionsList.new(sections: user.permanent_sections)
            end
          end
        end
      end
    end
  end

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

  def render_sign_in_button
    SidebarMenuButton(as: :a, href: view_context.new_user_session_path, size: :lg) do
      div(class: "flex h-8 w-8 items-center justify-center rounded-lg bg-sidebar-primary text-sidebar-primary-foreground shrink-0") do
        span(class: "text-sm font-semibold") { "?" }
      end
      div(class: "grid flex-1 text-left text-sm leading-tight group-data-[collapsible=icon]:hidden") do
        span(class: "truncate font-semibold") { "Sign In" }
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
    when :settings
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
        s.path(d: "M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z")
        s.circle(cx: "12", cy: "12", r: "3")
      end
    when :user
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
        s.path(d: "M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2")
        s.circle(cx: "12", cy: "7", r: "4")
      end
    when :log_out
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
        s.path(d: "M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4")
        s.polyline(points: "16 17 21 12 16 7")
        s.line(x1: "21", x2: "9", y1: "12", y2: "12")
      end
    end
  end
end

