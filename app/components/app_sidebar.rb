# frozen_string_literal: true

class ::Components::AppSidebar < ::Components::Base
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
        is_notes_page = @pathname.start_with?("/notes")
        is_journals_page = @pathname.start_with?("/journals") || @pathname.start_with?("/journal_")
        is_accounting_page = @pathname.start_with?("/accounting")
        is_checklists_page = @pathname.start_with?("/checklists")
        is_fixed_calendar_page = @pathname.start_with?("/fixed_calendar")
        is_admin_page = @pathname.start_with?("/admin")

        is_app_page_not_day_view = \
          is_well_page || \
          is_lists_page || \
          is_notes_page || \
          is_journals_page || \
          is_accounting_page || \
          is_checklists_page || \
          is_fixed_calendar_page || \
          is_admin_page

        if is_day_view
          # Show calendar for day view
          render_day_calendar
        elsif is_app_page_not_day_view
          SidebarMenu(class: "mt-4") do
            SidebarMenuItem do
              SidebarMenuButton(
                as: :a,
                href: authenticated_root_path,
                data: { action: "click->nav-loader#show" }
              ) do
                render ::Components::Icon::Calendar.new(size: "16", class: "shrink-0")
                span(class: "group-data-[collapsible=icon]:hidden") { "Today" }
              end
            end
          end
        else
          div(class: "mt-4")
        end

        SidebarMenu do
          SidebarMenuItem do
            SidebarMenuButton(as: :a, href: "#") do
              render ::Components::Icon::Droplet.new(size: "16", class: "shrink-0")
              span(class: "group-data-[collapsible=icon]:hidden") { "The Well" }
            end
          end
          SidebarMenuItem do
            SidebarMenuButton(
              as: :a,
              href: view_context.lists_path,
              data: { action: "click->nav-loader#show" }
            ) do
              render ::Components::Icon::List.new(size: "16", class: "shrink-0")
              span(class: "group-data-[collapsible=icon]:hidden") { "Lists" }
            end
          end
          SidebarMenuItem do
            SidebarMenuButton(
              as: :a,
              href: view_context.notes_path,
              data: { action: "click->nav-loader#show" }
            ) do
              render ::Components::Icon::StickyNote.new(size: "16", class: "shrink-0")
              span(class: "group-data-[collapsible=icon]:hidden") { "Notes" }
            end
          end
          SidebarMenuItem do
            SidebarMenuButton(
              as: :a,
              href: view_context.journals_path,
              data: { action: "click->nav-loader#show" }
            ) do
              render ::Components::Icon::Journal.new(size: "16", class: "shrink-0")
              span(class: "group-data-[collapsible=icon]:hidden") { "Journals" }
            end
          end
          SidebarMenuItem do
            SidebarMenuButton(
              as: :a,
              href: view_context.checklists_path,
              data: { action: "click->nav-loader#show" }
            ) do
              render ::Components::Icon::Checklist.new(size: "16", class: "shrink-0")
              span(class: "group-data-[collapsible=icon]:hidden") { "Checklists" }
            end
          end
          SidebarMenuItem do
            SidebarMenuButton(
              as: :a,
              href: view_context.fixed_calendar_path,
              data: { action: "click->nav-loader#show" }
            ) do
              render ::Components::Icon::Calendar.new(size: "16", class: "shrink-0")
              span(class: "group-data-[collapsible=icon]:hidden") { "Fixed Calendar" }
            end
          end
        end

        SidebarMenu do
          SidebarMenuItem do
            SidebarMenuButton(
              as: :a,
              href: view_context.accounting_index_path,
              data: {
                action: "click->nav-loader#show",
                turbo_prefetch: false
              }
            ) do
              render ::Components::Icon::Accounting.new(size: "16", class: "shrink-0")
              span(class: "group-data-[collapsible=icon]:hidden") { "Accounting" }
            end
          end
        end

        SidebarMenu do
          SidebarMenuItem do
            SidebarMenuButton(
              as: :a,
              href: view_context.admin_root_path,
              data: {
                action: "click->nav-loader#show",
                turbo_prefetch: false
              }
            ) do
              render ::Components::Icon::Settings.new(size: "16", class: "shrink-0")
              span(class: "group-data-[collapsible=icon]:hidden") { "Admin" }
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
              span(class: "text-sm font-semibold") { (user&.name&.split(" ")&.collect(&:first)&.join("") || "U").upcase }
            end
            div(class: "grid flex-1 text-left text-sm leading-tight group-data-[collapsible=icon]:hidden") do
              span(class: "truncate font-semibold") { user&.name&.split(" ")&.first || "User" }
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
              render ::Components::Icon::Settings.new(size: "16", class: "shrink-0")
              span(class: "ml-2") { "Settings" }
            end
          end

          render RubyUI::DropdownMenuItem.new(href: "#") do
            render ::Components::Icon::User.new(size: "16", class: "shrink-0")
            span(class: "ml-2") { "Edit Profile" }
          end

          render RubyUI::DropdownMenuSeparator.new

          # Theme toggle section - using DropdownMenuItem for consistent styling
          ThemeToggle do |toggle|
            toggle.SetLightMode do
              render RubyUI::DropdownMenuItem.new(href: "#") do
                render ::Components::Icon::Sun.new(size: "16", class: "shrink-0")
                span(class: "ml-2") { "Light mode" }
              end
            end

            toggle.SetDarkMode do
              render RubyUI::DropdownMenuItem.new(href: "#") do
                render ::Components::Icon::Moon.new(size: "16", class: "shrink-0")
                span(class: "ml-2") { "Dark mode" }
              end
            end
          end

          render RubyUI::DropdownMenuSeparator.new

          render RubyUI::DropdownMenuItem.new(href: view_context.destroy_user_session_path, data: { turbo_method: :delete }) do
            render ::Components::Icon::LogOut.new(size: "16", class: "shrink-0")
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
        render RubyUI::DialogTitle.new { "Settings" }
        render RubyUI::DialogDescription.new do
          plain "Configure your application settings"
        end
      end

      render RubyUI::DialogMiddle.new do
        render RubyUI::Tabs.new(default: "permanent_sections") do
          render RubyUI::TabsList.new do
            render RubyUI::TabsTrigger.new(value: "permanent_sections") { "Permanent Sections" }
            render RubyUI::TabsTrigger.new(value: "day_migration") { "Day Migration" }
            render RubyUI::TabsTrigger.new(value: "notifications") { "Notifications" }
            render RubyUI::TabsTrigger.new(value: "journal_protection") { "Journal Protection" }
          end

          # Permanent Sections Tab
          render RubyUI::TabsContent.new(value: "permanent_sections") do
            div(class: "space-y-4 mt-4") do
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
                  render ::Components::Settings::SectionsList.new(sections: user.permanent_sections)
                end
              end
            end
          end

          # Day Migration Tab
          render RubyUI::TabsContent.new(value: "day_migration") do
            div(class: "mt-4") do
              render ::Components::Settings::MigrationSettingsForm.new(settings: user.day_migration_settings)
            end
          end

          # Notifications Tab
          render RubyUI::TabsContent.new(value: "notifications") do
            div(class: "mt-4") do
              render ::Components::Settings::NotificationPreferencesTab.new(user: user)
            end
          end

          # Journal Protection Tab
          render RubyUI::TabsContent.new(value: "journal_protection") do
            div(class: "mt-4") do
              render ::Components::Settings::JournalProtectionTab.new(user: user)
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
          class: "inline-flex items-center justify-center w-full gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 border border-input bg-background shadow-sm hover:bg-accent hover:text-accent-foreground h-9 px-4 py-2",
          data: { action: "click->nav-loader#show" }
        ) do
          render ::Components::Icon::Calendar.new(size: "16", class: "shrink-0")
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
end
