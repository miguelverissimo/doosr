# frozen_string_literal: true

module Components
  module Checklists
    class Form < ::Components::Base
      def initialize(checklist_template: nil)
        @checklist_template = checklist_template || Checklist.new
        @is_new_record = @checklist_template.new_record?
        @action = @is_new_record ? "Create" : "Update"
        @items = @checklist_template.items || []
        super()
      end

      def view_template
        form_url = if @is_new_record
          view_context.checklists_path
        else
          view_context.checklist_path(@checklist_template)
        end

        render RubyUI::Form.new(
          action: form_url,
          method: "post",
          class: "space-y-6",
          data: {
            controller: "checklist-form modal-form",
            turbo: true,
            modal_form_loading_message_value: (@is_new_record ? "Creating checklist..." : "Updating checklist..."),
            modal_form_success_message_value: (@is_new_record ? "Checklist created successfully" : "Checklist updated successfully")
          }
        ) do
          # Hidden fields for Rails
          input(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)
          input(type: :hidden, name: "_method", value: "patch") unless @is_new_record
          input(type: :hidden, name: "checklist[kind]", value: "template")

          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new { "Name" }
            render RubyUI::Input.new(
              type: :text,
              name: "checklist[name]",
              id: "checklist_name",
              placeholder: "Enter checklist template name",
              value: @checklist_template.name.to_s,
              required: true
            )
            render RubyUI::FormFieldError.new
          end

          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new { "Description" }
            render RubyUI::Textarea.new(
              name: "checklist[description]",
              id: "checklist_description",
              placeholder: "Enter description",
              rows: 3,
              required: true
            ) do
              @checklist_template.description.to_s
            end
            render RubyUI::FormFieldError.new
          end

          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new { "Flow" }
            select(
              name: "checklist[flow]",
              id: "checklist_flow",
              class: "flex h-9 w-full rounded-md border bg-background px-3 py-1 text-sm shadow-sm transition-colors border-border focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring",
              required: true
            ) do
              Checklist.flows.each_key do |flow|
                option(
                  value: flow,
                  selected: @checklist_template.flow == flow.to_s
                ) { flow.to_s.humanize }
              end
            end
            render RubyUI::FormFieldError.new
          end

          # Items section
          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new { "Items" }
            div(
              class: "space-y-2",
              data: {
                checklist_form_target: "itemsContainer"
              }
            ) do
              # Hidden input to store items JSON
              input(
                type: :hidden,
                name: "checklist[items]",
                id: "checklist_items",
                data: {
                  checklist_form_target: "itemsInput"
                }
              )

              # Items list
              div(
                class: "space-y-2",
                data: {
                  checklist_form_target: "itemsList"
                }
              ) do
                @items.each_with_index do |item, index|
                  render_item_row(item, index)
                end
              end

              # Add item button
              Button(
                type: :button,
                variant: :secondary,
                size: :sm,
                data: {
                  action: "click->checklist-form#addItem"
                }
              ) do
                plain "Add Item"
              end
            end
            render RubyUI::FormFieldError.new
          end

          div(class: "flex gap-2 justify-end") do
            Button(variant: :outline, type: "button", data: { action: "click->ruby-ui--dialog#dismiss" }) { "Cancel" }
            Button(variant: :primary, type: "submit") { @action }
          end
        end
      end

      private

      def render_item_row(item, index)
        item_data = item.is_a?(Hash) ? item : item.to_h
        title = item_data["title"] || item_data[:title] || ""
        item_id = "item_#{index}"

        div(
          class: "flex items-center gap-2 p-2 border rounded-md bg-background",
          data: {
            checklist_form_target: "itemRow",
            item_index: index
          }
        ) do
          # Drag handle (for reordering)
          Button(
            type: :button,
            variant: :ghost,
            size: :sm,
            icon: true,
            class: "cursor-move text-muted-foreground hover:text-foreground",
            data: {
              action: "mousedown->checklist-form#startDrag",
              item_index: index
            },
            title: "Drag to reorder"
          ) do
            render ::Components::Icon.new(name: :more_vertical, size: "16")
          end

          # Item title input
          render RubyUI::Input.new(
            type: :text,
            class: "flex-1",
            placeholder: "Enter item title",
            value: title,
            data: {
              checklist_form_target: "itemTitle",
              item_index: index,
              action: "input->checklist-form#updateItem"
            }
          )

          # Move up button
          Button(
            type: :button,
            variant: :ghost,
            size: :sm,
            icon: true,
            class: "text-muted-foreground hover:text-foreground",
            data: {
              action: "click->checklist-form#moveUp",
              item_index: index
            },
            title: "Move up",
            disabled: index == 0
          ) do
            render ::Components::Icon.new(name: :arrow_up, size: "16")
          end

          # Move down button
          Button(
            type: :button,
            variant: :ghost,
            size: :sm,
            icon: true,
            class: "text-muted-foreground hover:text-foreground",
            data: {
              action: "click->checklist-form#moveDown",
              item_index: index
            },
            title: "Move down"
          ) do
            render ::Components::Icon.new(name: :arrow_down, size: "16")
          end

          # Remove button
          Button(
            type: :button,
            variant: :destructive,
            size: :sm,
            icon: true,
            class: "text-destructive hover:text-destructive",
            data: {
              action: "click->checklist-form#removeItem",
              item_index: index
            },
            title: "Remove item"
          ) do
            render ::Components::Icon.new(name: :x, size: "16")
          end
        end
      end
    end
  end
end
