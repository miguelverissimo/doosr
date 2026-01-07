module Views
  module Days
    class ActionsRow < ::Views::Base
      def initialize(day:)
        @day = day
      end

      def view_template
        # only show if day is not closed
        return if @day&.closed?

        div(class: "flex flex-wrap items-baseline gap-2 w-full") do
          # Add list link dropdown - only show if day exists and is not closed
          if @day && !@day.closed?
            render_list_selector
            render_separator
            render_checklist_selector
            render_separator
            render_add_note_button
            render_separator
          end

          # Form takes remaining space
          div(class: "flex-1 min-w-[12rem]") do
            render_add_item_form
          end
        end
      end

      private

      def render_separator
        div(class: "h-4 w-px bg-border mx-2")
      end

      def render_list_selector
        # Get already linked list IDs
        existing_list_ids = @day.descendant.extract_active_ids_by_type("List") +
                            @day.descendant.extract_inactive_ids_by_type("List")

        # Get user's available lists (excluding already linked ones)
        available_lists = view_context.current_user.lists.where.not(id: existing_list_ids).order(title: :asc)

        div(class: "relative mt-2", data: { controller: "dropdown" }) do
          # Dropdown trigger button
          Button(
            variant: :secondary,
            size: :md,
            data: { action: "click->dropdown#toggle" },
            disabled: available_lists.empty?
          ) do
            render ::Components::Icon.new(name: :link, size: "14")
            plain " Link list"
          end

          # Dropdown menu (hidden by default)
          div(
            data: { dropdown_target: "menu" },
            class: "hidden absolute left-0 mt-2 w-64 rounded-md shadow-lg bg-popover border z-50"
          ) do
            div(class: "p-2 space-y-1") do
              if available_lists.any?
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
                      class: "w-full text-left px-3 py-2 text-sm rounded-md hover:bg-accent cursor-pointer transition-colors"
                    ) do
                      div(class: "font-medium") { list.title }
                      div(class: "text-xs text-muted-foreground") do
                        item_count = list.descendant&.extract_active_ids_by_type("Item")&.count || 0
                        plain "#{item_count} items"
                      end
                    end
                  end
                end
              else
                div(class: "px-3 py-2 text-sm text-muted-foreground") do
                  plain "No lists available"
                end
              end
            end
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

        div(class: "relative mt-2", data: { controller: "dropdown" }) do
          # Dropdown trigger button
          Button(
            variant: :secondary,
            size: :md,
            data: { action: "click->dropdown#toggle" },
            disabled: available_templates.empty?
          ) do
            render ::Components::Icon.new(name: :checklist, size: "14")
            plain " Add checklist"
          end

          # Dropdown menu (hidden by default)
          div(
            data: { dropdown_target: "menu" },
            class: "hidden absolute left-0 mt-2 w-64 rounded-md shadow-lg bg-popover border z-50"
          ) do
            div(class: "p-2 space-y-1") do
              if available_templates.any?
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
                      class: "w-full text-left px-3 py-2 text-sm rounded-md hover:bg-accent cursor-pointer transition-colors"
                    ) do
                      div(class: "font-medium") { template.name }
                      div(class: "text-xs text-muted-foreground") do
                        item_count = template.items.length
                        plain "#{item_count} items • #{template.flow}"
                      end
                    end
                  end
                end
              else
                div(class: "px-3 py-2 text-sm text-muted-foreground") do
                  plain "No templates available"
                end
              end
            end
          end
        end
      end

      def render_add_note_button
        # Button to add a note to the day
        Button(
          variant: :secondary,
          size: :md,
          data: {
            controller: "day-note",
            day_note_day_id_value: @day.id,
            action: "click->day-note#openDialog"
          }
        ) do
          render ::Components::Icon.new(name: :sticky_note, size: "14")
          plain " Add note"
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
            # Completable button (selected by default)
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
              render ::Components::Icon.new(name: :completable, size: "16")
            end

            # Section button
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
              render ::Components::Icon.new(name: :section, size: "16")
            end
          end

          Input(
            type: "text",
            name: "item[title]",
            placeholder: "Add an item...",
            class: "flex-1 text-sm h-9",
            data: { item_form_target: "titleInput" },
            required: true
          )

          # Submit button
          Button(type: :submit, variant: :primary, size: :sm, class: "shrink-0 h-9 w-9") { "Add" }
        end
      end
    end
  end
end
