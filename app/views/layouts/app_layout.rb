# frozen_string_literal: true

class ::Views::Layouts::AppLayout < ::Views::Base
  include Phlex::Rails::Layout

  def initialize(pathname:, selected_date: nil, day: nil, latest_importable_day: nil, list: nil, checklist: nil)
    @pathname = pathname
    @selected_date = selected_date
    @day = day
    @latest_importable_day = latest_importable_day
    @list = list
    @checklist = checklist
  end

  private

  def render_flash_toasts
    Rails.logger.debug "=== FLASH DEBUG START ==="
    Rails.logger.debug "Flash notice: #{view_context.flash[:notice].inspect}"
    Rails.logger.debug "Flash alert: #{view_context.flash[:alert].inspect}"
    Rails.logger.debug "Flash toast: #{view_context.flash[:toast].inspect}"
    Rails.logger.debug "Flash keys: #{view_context.flash.keys.inspect}"

    return unless view_context.flash[:notice].present? || view_context.flash[:alert].present? || view_context.flash[:toast].present?

    # Create a unique key for this flash message
    flash_key = "#{view_context.flash[:notice]}#{view_context.flash[:alert]}#{view_context.flash[:toast]}".hash.to_s

    script_content = "if (!window.flashToastKeys) { window.flashToastKeys = {}; } "
    script_content += "if (window.flashToastKeys['#{flash_key}']) { } else { "
    script_content += "window.flashToastKeys['#{flash_key}'] = true; "
    script_content += "(function() { "
    script_content += "function showFlashToast() { "
    script_content += "var attempts = 0; "
    script_content += "var maxAttempts = 50; "
    script_content += "function tryShowToast() { "
    script_content += "attempts++; "
    script_content += "if (typeof window.toast !== 'undefined' && window.toast) { "

    # Handle flash[:toast] with full options
    if view_context.flash[:toast].present?
      toast_data = view_context.flash[:toast]
      Rails.logger.debug "Processing flash[:toast]: #{toast_data.inspect}"
      if toast_data.is_a?(Hash)
        message = toast_data[:message] || toast_data["message"] || ""
        description = toast_data[:description] || toast_data["description"] || ""
        type = toast_data[:type] || toast_data["type"] || "default"
        position = toast_data[:position] || toast_data["position"] || "top-center"
        icon = toast_data[:icon] || toast_data["icon"] || nil

        toast_options = { type: type, description: description, position: position }
        toast_options[:icon] = icon if icon

        script_content += "window.toast(#{message.to_json}, #{toast_options.to_json}); "
      else
        script_content += "window.toast(#{toast_data.to_json}); "
      end
    end

    # Handle flash[:notice] as success toast
    if view_context.flash[:notice].present?
      Rails.logger.debug "Processing flash[:notice]: #{view_context.flash[:notice].inspect}"
      script_content += "window.toast(#{view_context.flash[:notice].to_json}, { type: 'success' }); "
    end

    # Handle flash[:alert] as danger toast
    if view_context.flash[:alert].present?
      Rails.logger.debug "Processing flash[:alert]: #{view_context.flash[:alert].inspect}"
      script_content += "window.toast(#{view_context.flash[:alert].to_json}, { type: 'danger' }); "
    end

    script_content += "} else if (attempts < maxAttempts) { "
    script_content += "setTimeout(tryShowToast, 100); "
    script_content += "} "
    script_content += "} "
    script_content += "tryShowToast(); "
    script_content += "} "
    script_content += "var flashToastListenerAdded = false; "
    script_content += "function addFlashToastListener() { "
    script_content += "if (flashToastListenerAdded) { return; } "
    script_content += "flashToastListenerAdded = true; "
    script_content += "if (typeof Turbo !== 'undefined') { "
    script_content += "document.addEventListener('turbo:load', showFlashToast, { once: true }); "
    script_content += "} else if (document.readyState === 'loading') { "
    script_content += "document.addEventListener('DOMContentLoaded', showFlashToast, { once: true }); "
    script_content += "} else { "
    script_content += "setTimeout(showFlashToast, 50); "
    script_content += "} "
    script_content += "} "
    script_content += "addFlashToastListener(); "
    script_content += "})(); "
    script_content += "}"

    Rails.logger.debug "Generated script content length: #{script_content.length}"
    Rails.logger.debug "=== FLASH DEBUG END ==="

    raw "<script type=\"text/javascript\">#{script_content}</script>".html_safe
  end

  def view_template
    doctype
    html do
      head do
        title { yield(:title).presence || "Doosr" }
        meta(name: "viewport", content: "width=device-width,initial-scale=1")
        meta(name: "turbo-prefetch", content: "false")
        meta(name: "apple-mobile-web-app-capable", content: "yes")
        meta(name: "apple-mobile-web-app-status-bar-style", content: "default")
        meta(name: "application-name", content: "Doosr")
        meta(name: "mobile-web-app-capable", content: "yes")
        meta(name: "theme-color", content: "#ffffff")
        raw(view_context.csrf_meta_tags)
        raw(view_context.csp_meta_tag)
        yield(:head)
        link(rel: "icon", href: "/favicon-96x96.png", sizes: "96x96")
        link(rel: "icon", href: "/favicon.svg", type: "image/svg+xml")
        link(rel: "shortcut icon", href: "/favicon.ico")
        link(rel: "apple-touch-icon", sizes: "180x180", href: "/apple-touch-icon.png")
        meta(name: "apple-mobile-web-app-title", content: "Doosr")
        link(rel: "manifest", href: "/site.webmanifest")
        raw(view_context.stylesheet_link_tag("tailwind", "data-turbo-track": "reload"))
        raw(view_context.stylesheet_link_tag("checkbox_fix", "data-turbo-track": "reload"))
        raw(view_context.javascript_importmap_tags)
      end

      body(data: { controller: "pwa nav-loader" }) do
        render ::Components::Toast.new

        # Global navigation loading spinner
        div(
          id: "nav_loading_spinner",
          class: "hidden fixed inset-0 z-50 flex items-center justify-center bg-background/80 backdrop-blur-sm",
          data: { nav_loader_target: "spinner" }
        ) do
          div(class: "flex flex-col items-center gap-4") do
            svg(
              class: "animate-spin h-12 w-12 text-primary",
              xmlns: "http://www.w3.org/2000/svg",
              fill: "none",
              viewBox: "0 0 24 24"
            ) do |s|
              s.circle(
                class: "opacity-25",
                cx: "12",
                cy: "12",
                r: "10",
                stroke: "currentColor",
                stroke_width: "4"
              )
              s.path(
                class: "opacity-75",
                fill: "currentColor",
                d: "M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
              )
            end
            p(class: "text-sm text-muted-foreground") { "Loading..." }
          end
        end

        SidebarWrapper do
          render ::Components::AppSidebar.new(pathname: @pathname, selected_date: @selected_date)

          SidebarInset do
            header(class: "sticky top-0 z-10 flex h-16 shrink-0 items-center gap-2 border-b bg-background px-4") do
              SidebarTrigger(class: "-ml-1")

              if @selected_date
                div(id: "day_header", class: "flex items-center gap-3 flex-1") do
                  render ::Views::Days::Header.new(
                    date: @selected_date,
                    day: @day,
                    latest_importable_day: @latest_importable_day
                  )
                end

                # Ephemeries button
                Button(
                  variant: :ghost,
                  icon: true,
                  size: :sm,
                  class: "ml-2",
                  data: {
                    controller: "ephemeries",
                    ephemeries_date_value: @selected_date.to_s,
                    action: "click->ephemeries#open"
                  },
                  title: "View ephemeries"
                ) do
                  # Star/sparkles icon for astrological aspects
                  svg(
                    xmlns: "http://www.w3.org/2000/svg",
                    class: "h-4 w-4",
                    viewBox: "0 0 24 24",
                    fill: "none",
                    stroke: "currentColor",
                    stroke_width: "2",
                    stroke_linecap: "round",
                    stroke_linejoin: "round"
                  ) do |s|
                    s.path(d: "M12 3l2.598 7.026L22 12l-7.402 1.974L12 21l-2.598-7.026L2 12l7.402-1.974L12 3z")
                  end
                end
              elsif @pathname == "/lists" || @pathname == "/lists/"
                # Lists index page
                render ::Views::Lists::Header.new
              elsif @pathname == "/checklists" || @pathname == "/checklists/"
                # Checklists page
                render ::Views::Checklists::Header.new
              elsif @checklist
                # Individual checklist show page
                div(class: "flex items-center gap-3 flex-1") do
                  h1(class: "font-semibold text-base truncate") { @checklist.name }
                end
              elsif @pathname == "/accounting" || @pathname == "/accounting/"
                # Accounting page
                render ::Views::Accounting::Header.new
              elsif @pathname == "/fixed_calendar" || @pathname == "/fixed_calendar/"
                # Fixed Calendar page
                render ::Views::FixedCalendar::Header.new
              end

              div(class: "flex items-center gap-2") do
                ThemeToggle do |toggle|
                  toggle.SetLightMode do
                    Button(variant: :outline, icon: true) do
                      svg(
                        xmlns: "http://www.w3.org/2000/svg",
                        viewbox: "0 0 24 24",
                        fill: "currentColor",
                        class: "w-4 h-4"
                      ) do |s|
                        s.path(
                          d: "M12 2.25a.75.75 0 01.75.75v2.25a.75.75 0 01-1.5 0V3a.75.75 0 01.75-.75zM7.5 12a4.5 4.5 0 119 0 4.5 4.5 0 01-9 0zM18.894 6.166a.75.75 0 00-1.06-1.06l-1.591 1.59a.75.75 0 101.06 1.061l1.591-1.59zM21.75 12a.75.75 0 01-.75.75h-2.25a.75.75 0 010-1.5H21a.75.75 0 01.75.75zM17.834 18.894a.75.75 0 001.06-1.06l-1.59-1.591a.75.75 0 10-1.061 1.06l1.59 1.591zM12 18a.75.75 0 01.75.75V21a.75.75 0 01-1.5 0v-2.25A.75.75 0 0112 18zM7.758 17.303a.75.75 0 00-1.061-1.06l-1.591 1.59a.75.75 0 001.06 1.061l1.591-1.59zM6 12a.75.75 0 01-.75.75H3a.75.75 0 010-1.5h2.25A.75.75 0 016 12zM6.697 7.757a.75.75 0 001.06-1.06l-1.59-1.591a.75.75 0 00-1.061 1.06l1.59 1.591z"
                        )
                      end
                    end
                  end

                  toggle.SetDarkMode do
                    Button(variant: :outline, icon: true) do
                      svg(
                        xmlns: "http://www.w3.org/2000/svg",
                        viewbox: "0 0 24 24",
                        fill: "currentColor",
                        class: "w-4 h-4"
                      ) do |s|
                        s.path(
                          fill_rule: "evenodd",
                          d: "M9.528 1.718a.75.75 0 01.162.819A8.97 8.97 0 009 6a9 9 0 009 9 8.97 8.97 0 003.463-.69.75.75 0 01.981.98 10.503 10.503 0 01-9.694 6.46c-5.799 0-10.5-4.701-10.5-10.5 0-4.368 2.667-8.112 6.46-9.694a.75.75 0 01.818.162z",
                          clip_rule: "evenodd"
                        )
                      end
                    end
                  end
                end

                Form(action: destroy_user_session_path, method: "post", class: "inline-block") do
                  csrf_token_field
                  input(type: "hidden", name: "_method", value: "delete")
                  Button(type: :submit, variant: :ghost, size: :sm) { "Sign out" }
                end
              end
            end

            div(class: "vertical mx-auto mt-0 w-full max-w-[var(--container-max-width)] flex-1 px-4 py-4") do
              render_flash_toasts

              # Turbo frame for day migration modal
              div(id: "day_migration_modal")

              # Container for ritual modals
              div(id: "ritual_modal_container")

              yield
            end
          end
        end
      end
    end
  end
end
