# frozen_string_literal: true

module Components
  module Settings
    class MigrationSettingsForm < ::Components::Base
      def initialize(settings: {}, **attrs)
        @settings = settings
        super(**attrs)
      end

      def view_template
        form(
          action: view_context.update_migration_settings_settings_path,
          method: "post",
          class: "space-y-6",
          "data-turbo-method": "patch",
          data: {
            controller: "migration-settings-form",
            action: "submit->migration-settings-form#submit"
          }
        ) do
          view_context.hidden_field_tag :authenticity_token, view_context.form_authenticity_token
          view_context.hidden_field_tag :_method, "patch"

          # Dynamically render migration options
          div(class: "space-y-3") do
            label(class: "text-sm font-semibold mb-3 block") { "Day Settings" }

            # Render top-level options
            MigrationOptions.top_level_options.each do |key, config|
              render_toggle_field(
                name: "day_migration_settings[#{key}]",
                label: config[:label],
                description: config[:description],
                checked: @settings.dig(key.to_s)
              )
            end

            # Render nested option groups
            MigrationOptions.nested_option_groups.each do |group_key, group_config|
              div(class: "pt-4") do
                label(class: "text-sm font-semibold mb-3 block") { group_config[:label] }

                div(class: "space-y-3 pl-4") do
                  MigrationOptions.options_for_group(group_key).each do |option_key, option_config|
                    render_toggle_field(
                      name: "day_migration_settings[#{group_key}][#{option_key}]",
                      label: option_config[:label],
                      description: option_config[:description],
                      checked: @settings.dig(group_key.to_s, option_key.to_s)
                    )
                  end
                end
              end
            end
          end

          # Save button
          div(class: "pt-4 flex justify-end") do
            button(
              type: "submit",
              class: "inline-flex items-center justify-center rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 bg-primary text-primary-foreground hover:bg-primary/90 disabled:opacity-50 disabled:cursor-not-allowed h-10 px-4 py-2",
              data: {
                migration_settings_form_target: "submitButton"
              }
            ) do
              span(data: { migration_settings_form_target: "buttonText" }) { "Save Settings" }
            end
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
            # Hidden field to ensure false is sent when unchecked
            input(type: "hidden", name: name, value: "false")

            input(
              type: "checkbox",
              name: name,
              value: "true",
              id: name.tr("[]", "_"),
              class: "sr-only peer",
              checked: checked,
              data: {
                action: "change->migration-settings-form#checkboxChanged"
              }
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
