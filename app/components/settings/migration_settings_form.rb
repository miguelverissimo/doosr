# frozen_string_literal: true

module Components
  module Settings
    class MigrationSettingsForm < Components::Base
      def initialize(settings: {}, **attrs)
        @settings = settings
        super(**attrs)
      end

      def view_template
        form(
          action: view_context.update_migration_settings_settings_path,
          method: "post",
          class: "space-y-6",
          data: {
            controller: "migration-settings-form",
            action: "submit->migration-settings-form#submit"
          }
        ) do
          view_context.hidden_field_tag :authenticity_token, view_context.form_authenticity_token
          view_context.hidden_field_tag :_method, "patch"

          # Links toggle
          div(class: "space-y-3") do
            render_toggle_field(
              name: "day_migration_settings[links]",
              label: "Migrate Links",
              description: "Include links when importing from previous day",
              checked: @settings.dig("links")
            )

            render_toggle_field(
              name: "day_migration_settings[active_item_sections]",
              label: "Migrate Active Item Sections",
              description: "Include active item sections when importing",
              checked: @settings.dig("active_item_sections")
            )

            render_toggle_field(
              name: "day_migration_settings[notes]",
              label: "Migrate Notes",
              description: "Include notes when importing",
              checked: @settings.dig("notes")
            )

            # Items section
            div(class: "pt-4 border-t") do
              label(class: "text-sm font-semibold mb-3 block") { "Item Settings" }

              div(class: "space-y-3 pl-4") do
                render_toggle_field(
                  name: "day_migration_settings[items][sections]",
                  label: "Migrate Sections",
                  description: "Include section items",
                  checked: @settings.dig("items", "sections")
                )

                render_toggle_field(
                  name: "day_migration_settings[items][notes]",
                  label: "Migrate Item Notes",
                  description: "Include notes within items",
                  checked: @settings.dig("items", "notes")
                )
              end
            end
          end

          # Save button
          div(class: "pt-4 flex justify-end") do
            button(
              type: "submit",
              class: "inline-flex items-center justify-center rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 bg-primary text-primary-foreground hover:bg-primary/90 h-10 px-4 py-2"
            ) { "Save Settings" }
          end
        end
      end

      private

      def render_toggle_field(name:, label:, description:, checked:)
        div(class: "flex items-start justify-between space-x-4 rounded-lg border p-4") do
          div(class: "flex-1") do
            label(class: "text-sm font-medium leading-none block mb-1", for: name.tr("[]", "_")) { label }
            p(class: "text-sm text-muted-foreground") { description }
          end

          # Toggle switch
          label(class: "relative inline-flex items-center cursor-pointer") do
            input(
              type: "checkbox",
              name: name,
              value: "true",
              id: name.tr("[]", "_"),
              class: "sr-only peer",
              checked: checked
            )

            div(
              class: [
                "w-11 h-6 bg-input rounded-full peer",
                "peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-ring peer-focus:ring-offset-2",
                "peer-checked:after:translate-x-full",
                "after:content-[''] after:absolute after:top-0.5 after:left-[2px]",
                "after:bg-background after:rounded-full after:h-5 after:w-5",
                "after:transition-all peer-checked:bg-primary"
              ]
            )
          end
        end
      end
    end
  end
end
