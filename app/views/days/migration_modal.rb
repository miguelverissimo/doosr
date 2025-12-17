# frozen_string_literal: true

module Views
  module Days
    class MigrationModal < Views::Base
      def initialize(date:, latest_importable_day:, migration_settings: {})
        @date = date
        @latest_importable_day = latest_importable_day
        @migration_settings = migration_settings
      end

      def view_template
        render RubyUI::Dialog.new(open: true) do
          render RubyUI::DialogContent.new(size: :md) do
            render RubyUI::DialogHeader.new do
              render RubyUI::DialogTitle.new { "Choose what to import from #{format_date(@latest_importable_day.date)}" }
            end

            render RubyUI::DialogMiddle.new do
              form(
                action: view_context.day_migrations_path(date: @date),
                method: "post",
                class: "space-y-6",
                data: {
                  controller: "migration-form",
                  action: "submit->migration-form#submit"
                }
              ) do
                view_context.hidden_field_tag :authenticity_token, view_context.form_authenticity_token
                # CRITICAL: Pass date as query param in action URL AND as hidden field
                view_context.hidden_field_tag :date, @date.to_s

                # Migration options
                div(class: "space-y-3") do
                  # Render top-level options
                  MigrationOptions.top_level_options.each do |key, config|
                    render_toggle_field(
                      name: "day_migration_settings[#{key}]",
                      label: config[:label],
                      description: config[:description],
                      checked: @migration_settings.dig(key.to_s)
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
                            checked: @migration_settings.dig(group_key.to_s, option_key.to_s)
                          )
                        end
                      end
                    end
                  end
                end

                # Action buttons
                render RubyUI::DialogFooter.new do
                  button(
                    type: "button",
                    class: "inline-flex items-center justify-center rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 border border-input bg-background hover:bg-accent hover:text-accent-foreground h-10 px-4 py-2",
                    data: {
                      action: "click->migration-form#cancel"
                    }
                  ) { "Cancel" }

                  button(
                    type: "submit",
                    class: "inline-flex items-center justify-center rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 bg-primary text-primary-foreground hover:bg-primary/90 h-10 px-4 py-2"
                  ) { "Migrate from #{format_date(@latest_importable_day.date)}" }
                end
              end
            end
          end
        end
      end

      private

      def format_date(date)
        date.strftime("%b %-d, %Y")
      end

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
