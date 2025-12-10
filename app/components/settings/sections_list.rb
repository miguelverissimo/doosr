# frozen_string_literal: true

module Components
  module Settings
    class SectionsList < Components::Base
      def initialize(sections: [], **attrs)
        @sections = sections
        super(**attrs)
      end

      def view_template
        if @sections.empty?
          div(class: "text-sm text-muted-foreground py-4 text-center") do
            "No sections yet. Add your first section above."
          end
        else
          div(class: "space-y-2") do
            @sections.each do |section|
              render_section_item(section)
            end
          end
        end
      end

      private

      def render_section_item(section)
        section_index = @sections.index(section)
        is_first = section_index == 0
        is_last = section_index == @sections.length - 1

        div(
          class: "flex items-center justify-between rounded-lg border bg-card p-3 hover:bg-accent/50 transition-colors",
          id: "section_#{section.parameterize}",
          data: { controller: "section-edit" }
        ) do
          # Left side: section name (display mode)
          span(class: "font-medium section-name", data: { section_edit_target: "displayName" }) { section }

          # Left side: edit form (hidden by default)
          form(
            id: "edit_form_#{section.parameterize}",
            action: view_context.edit_section_settings_path(old_name: section),
            method: "post",
            class: "hidden gap-2 flex-1",
            style: "display: none;",
            data: { section_edit_target: "editForm", turbo_method: "patch" }
          ) do
            raw view_context.hidden_field_tag(:_method, "patch")
            raw view_context.hidden_field_tag(:authenticity_token, view_context.form_authenticity_token)

            input(
              type: "text",
              name: "new_name",
              value: section,
              class: "flex-1 rounded-md border border-input bg-background px-2 py-1 text-sm",
              required: true
            )

            button(
              type: "submit",
              class: "inline-flex items-center justify-center rounded-md text-sm font-medium bg-primary text-primary-foreground hover:bg-primary/90 h-8 px-3"
            ) { "Save" }

            button(
              type: "button",
              class: "inline-flex items-center justify-center rounded-md text-sm font-medium border border-input bg-background hover:bg-accent h-8 px-3",
              data: { action: "click->section-edit#cancel" }
            ) { "Cancel" }
          end

          # Right side: buttons (edit, up, down, delete)
          div(class: "flex items-center gap-1") do
            # Edit button
            button(
              type: "button",
              class: "inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors hover:bg-accent hover:text-accent-foreground h-8 w-8",
              aria_label: "Edit section",
              data: { action: "click->section-edit#edit" }
            ) do
              render_edit_icon
            end

            # Move up button
            form(
              action: view_context.move_section_settings_path(section_name: section),
              method: "post",
              class: "inline",
              data: { turbo_method: "patch" }
            ) do
              raw view_context.hidden_field_tag(:_method, "patch")
              raw view_context.hidden_field_tag(:direction, "up")
              raw view_context.hidden_field_tag(:authenticity_token, view_context.form_authenticity_token)

              button(
                type: "submit",
                class: "inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors hover:bg-accent hover:text-accent-foreground h-8 w-8 #{is_first ? 'opacity-30 cursor-not-allowed' : ''}",
                aria_label: "Move section up",
                disabled: is_first
              ) do
                render_chevron_up
              end
            end

            # Move down button
            form(
              action: view_context.move_section_settings_path(section_name: section),
              method: "post",
              class: "inline",
              data: { turbo_method: "patch" }
            ) do
              raw view_context.hidden_field_tag(:_method, "patch")
              raw view_context.hidden_field_tag(:direction, "down")
              raw view_context.hidden_field_tag(:authenticity_token, view_context.form_authenticity_token)

              button(
                type: "submit",
                class: "inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors hover:bg-accent hover:text-accent-foreground h-8 w-8 #{is_last ? 'opacity-30 cursor-not-allowed' : ''}",
                aria_label: "Move section down",
                disabled: is_last
              ) do
                render_chevron_down
              end
            end

            # Delete button
            form(
              action: view_context.remove_section_settings_path(section_name: section),
              method: "post",
              class: "inline",
              data: { turbo_method: "delete" }
            ) do
              raw view_context.hidden_field_tag(:_method, "delete")
              raw view_context.hidden_field_tag(:authenticity_token, view_context.form_authenticity_token)

              button(
                type: "submit",
                class: "inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors hover:bg-destructive hover:text-destructive-foreground h-8 w-8 text-muted-foreground",
                aria_label: "Delete section",
                data: { confirm: "Are you sure you want to delete the '#{section}' section?" }
              ) do
                render_trash_icon
              end
            end
          end
        end
      end

      def render_chevron_down
        svg(
          xmlns: "http://www.w3.org/2000/svg",
          width: "16",
          height: "16",
          viewBox: "0 0 24 24",
          fill: "none",
          stroke: "currentColor",
          stroke_width: "2",
          stroke_linecap: "round",
          stroke_linejoin: "round"
        ) do |s|
          s.path(d: "m6 9 6 6 6-6")
        end
      end

      def render_chevron_up
        svg(
          xmlns: "http://www.w3.org/2000/svg",
          width: "16",
          height: "16",
          viewBox: "0 0 24 24",
          fill: "none",
          stroke: "currentColor",
          stroke_width: "2",
          stroke_linecap: "round",
          stroke_linejoin: "round"
        ) do |s|
          s.path(d: "m18 15-6-6-6 6")
        end
      end

      def render_trash_icon
        svg(
          xmlns: "http://www.w3.org/2000/svg",
          width: "16",
          height: "16",
          viewBox: "0 0 24 24",
          fill: "none",
          stroke: "currentColor",
          stroke_width: "2",
          stroke_linecap: "round",
          stroke_linejoin: "round"
        ) do |s|
          s.path(d: "M3 6h18")
          s.path(d: "M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6")
          s.path(d: "M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2")
        end
      end

      def render_edit_icon
        svg(
          xmlns: "http://www.w3.org/2000/svg",
          width: "16",
          height: "16",
          viewBox: "0 0 24 24",
          fill: "none",
          stroke: "currentColor",
          stroke_width: "2",
          stroke_linecap: "round",
          stroke_linejoin: "round"
        ) do |s|
          s.path(d: "M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z")
          s.path(d: "m15 5 4 4")
        end
      end
    end
  end
end
