module Views
  module Days
    module Mobile
      class ActionsRow < ::Views::Base
        def initialize(day:)
          @day = day
        end

        def view_template
          # only show if day is not closed
          return if @day&.closed?

          div(class: "space-y-2") do
            render_primary_bar
            render_secondary_actions
          end
        end

        private

        def render_primary_bar
          div(class: "rounded-lg border bg-card px-3 py-2") do
            render_add_item_form
          end
        end

        def render_secondary_actions
          return unless @day && !@day.closed?

          div(class: "flex items-center justify-end gap-2") do
            div(class: "relative", data: { controller: "dropdown" }) do
              Button(
                variant: :outline,
                size: :sm,
                data: { action: "click->dropdown#toggle" }
              ) do
                plain "More actions "
                render ::Components::Icon::ChevronDown.new(size: "16")
              end

              div(
                data: { dropdown_target: "menu" },
                class: "hidden absolute right-0 z-50 mt-2 w-56 rounded-md border bg-popover shadow-lg"
              ) do
                div(class: "p-1 space-y-1") do
                  render_list_selector
                  render_checklist_selector
                  render_add_note_button
                  render_add_journal_button
                end
              end
            end
          end
        end

        def render_list_selector
          # Get already linked list IDs
          existing_list_ids = @day.descendant.extract_active_ids_by_type("List") +
                              @day.descendant.extract_inactive_ids_by_type("List")

          # Get user's available lists (excluding already linked ones)
          available_lists = view_context.current_user.lists.where.not(id: existing_list_ids).order(title: :asc)

          if available_lists.any?
            div(class: "border-b border-border last:border-0") do
              div(class: "px-2 py-2 text-xs text-muted-foreground flex items-center") do
                render ::Components::Icon::List.new(size: "14", class: "mr-2")
                plain "Link list"
              end

              div(class: "max-h-56 overflow-y-auto") do
                available_lists.each do |list|
                  form(
                    action: day_list_links_path,
                    method: "post",
                    data: {
                      turbo_stream: true,
                      controller: "form-loading",
                      form_loading_message_value: "Adding list link...",
                      action: "submit->form-loading#submit"
                    }
                  ) do
                    csrf_token_field
                    input(type: "hidden", name: "list_id", value: list.id)
                    input(type: "hidden", name: "day_id", value: @day.id)

                    button(
                      type: "submit",
                      class: "w-full px-2 py-2 text-left text-sm rounded-md hover:bg-accent cursor-pointer transition-colors"
                    ) do
                      div(class: "font-medium truncate") { list.title }
                      div(class: "text-xs text-muted-foreground") do
                        item_count = list.descendant&.extract_active_ids_by_type("Item")&.count || 0
                        plain "#{item_count} items"
                      end
                    end
                  end
                end
              end
            end
          else
            div(class: "px-2 py-2 text-xs text-muted-foreground flex items-center") do
              render ::Components::Icon::List.new(size: "14", class: "mr-2")
              plain "No lists available"
            end
          end
        end

        def render_checklist_selector
          # Get already linked checklist IDs from the day
          existing_checklist_ids = @day.descendant.extract_active_ids_by_type("Checklist") +
                                    @day.descendant.extract_inactive_ids_by_type("Checklist")

          # Get template IDs that are already used by linked checklists
          existing_template_ids = if existing_checklist_ids.any?
            Checklist.where(id: existing_checklist_ids).pluck(:template_id).compact
          else
            []
          end

          # Get user's available checklist templates (excluding already linked ones)
          available_templates = view_context.current_user.checklists.template
            .where.not(id: existing_template_ids)
            .order(name: :asc)

          if available_templates.any?
            div(class: "border-b border-border last:border-0") do
              div(class: "px-2 py-2 text-xs text-muted-foreground flex items-center") do
                render ::Components::Icon::Checklist.new(size: "14", class: "mr-2")
                plain "Add checklist"
              end

              div(class: "max-h-56 overflow-y-auto") do
                available_templates.each do |template|
                  form(
                    action: day_checklist_links_path,
                    method: "post",
                    data: {
                      turbo_stream: true,
                      controller: "form-loading",
                      form_loading_message_value: "Adding checklist...",
                      action: "submit->form-loading#submit turbo:submit-end->dropdown#toggle"
                    }
                  ) do
                    csrf_token_field
                    input(type: "hidden", name: "template_id", value: template.id)
                    input(type: "hidden", name: "day_id", value: @day.id)

                    button(
                      type: "submit",
                      class: "w-full px-2 py-2 text-left text-sm rounded-md hover:bg-accent cursor-pointer transition-colors"
                    ) do
                      div(class: "font-medium truncate") { template.name }
                      div(class: "text-xs text-muted-foreground") do
                        item_count = template.items.length
                        plain "#{item_count} items • #{template.flow}"
                      end
                    end
                  end
                end
              end
            end
          else
            div(class: "px-2 py-2 text-xs text-muted-foreground flex items-center") do
              render ::Components::Icon::Checklist.new(size: "14", class: "mr-2")
              plain "No templates available"
            end
          end
        end

        def render_add_note_button
          div(class: "py-1.5") do
            Button(
              variant: :ghost,
              size: :sm,
              class: "w-full justify-start",
              data: {
                controller: "day-note",
                day_note_day_id_value: @day.id,
                action: "click->day-note#openDialog"
              }
            ) do
              render ::Components::Icon::StickyNote.new(size: "14", class: "mr-2")
              plain "Add note"
            end
          end
        end

        def render_add_journal_button
          # Check if journal already linked
          existing_journal_ids = @day.descendant.extract_active_ids_by_type("Journal")
          already_linked = existing_journal_ids.any?

          form(
            action: day_journal_links_path,
            method: "post",
            data: {
              turbo_stream: true,
              controller: "form-loading",
              form_loading_message_value: "Adding journal link...",
              action: "submit->form-loading#submit"
            }
          ) do
            csrf_token_field
            input(type: "hidden", name: "day_id", value: @day.id)

            div(class: "py-1.5") do
              Button(
                type: :submit,
                variant: :ghost,
                class: "w-full justify-start",
                size: :sm,
                disabled: already_linked
              ) do
                render ::Components::Icon::Journal.new(size: "14", class: "mr-2")
                plain "Add journal"
              end
            end
          end
        end

        def render_add_item_form
          form(
            action: items_path,
            method: "post",
            data: {
              controller: "item-form",
              action: "submit->item-form#submit turbo:submit-end->item-form#clearForm",
              turbo: "true"
            },
            class: "flex items-center gap-2"
          ) do
            csrf_token_field
            if @day
              input(type: "hidden", name: "day_id", value: @day.id)
            else
              input(type: "hidden", name: "date", value: @date.to_s)
            end
            input(
              type: "hidden",
              name: "item[item_type]",
              value: "completable",
              data: { item_form_target: "itemType" }
            )

            # Type selector buttons
            div(class: "flex gap-1") do
              Button(
                type: :button,
                variant: :outline,
                icon: true,
                size: :sm,
                class: "shrink-0 h-9 w-9 bg-secondary text-secondary-foreground hover:bg-secondary/90",
                data: {
                  action: "click->item-form#selectCompletable",
                  item_form_target: "completableButton"
                }
              ) do
                render ::Components::Icon::Completable.new(size: "16")
              end

              Button(
                type: :button,
                variant: :outline,
                icon: true,
                size: :sm,
                class: "shrink-0 h-9 w-9",
                data: {
                  action: "click->item-form#selectSection",
                  item_form_target: "sectionButton"
                }
              ) do
                render ::Components::Icon::Section.new(size: "16")
              end
            end

            Input(
              type: "text",
              name: "item[title]",
              placeholder: "Add an item...",
              class: "flex-1 text-sm h-10",
              data: { item_form_target: "titleInput" },
              required: true
            )

            Button(type: :submit, variant: :primary, size: :sm, class: "shrink-0 h-10 px-3") { "Add" }
          end
        end
      end
    end
  end
end
