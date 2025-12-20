module Views
  module Checklists
    class TemplateRow < Views::Base
      def initialize(checklist:)
        @checklist = checklist
      end

      def view_template
        div(
          id: "checklist_#{@checklist.id}_div", 
          class: "flex flex-col w-full gap-2 rounded-md p-3 text-left transition-colors border border-border bg-muted hover:bg-muted/50 mt-2"
        ) do
          div(class: "flex flex-row items-center justify-between gap-2") do
            div(class: "text-md font-bold mt-1") { @checklist.name }

            div(class: "flex flex-row text-sm text-muted-foreground gap-2") do
              render_kind_badge
              render_flow_badge
            end
          end

          div(class: "flex flex-row items-center justify-between gap-2") do
            div(class: "text-sm") do
              @checklist.description.to_s
            end

            # Right column: buttons
            div(class: "flex items-center gap-2 shrink-0") do
              # Edit button with dialog
              render RubyUI::Dialog.new do
                render RubyUI::DialogTrigger.new do
                  Button(variant: :outline, icon: true) do
                    render Components::Icon.new(name: :edit, size: "12", class: "w-5 h-5")
                  end
                end
                render_edit_dialog
              end

              # Delete button with AlertDialog confirmation
              render_delete_confirmation_dialog
            end
          end

          if @checklist.items.any?
            items_count = @checklist.items.count
            items_to_show = @checklist.items.first(9)
            
            # Calculate how many columns we actually need (1, 2, or 3)
            num_columns = [items_to_show.length, 3].min
            
            # Use appropriate grid class based on number of columns
            grid_class = case num_columns
            when 1
              "grid grid-cols-1 gap-2"
            when 2
              "grid grid-cols-2 gap-2"
            else
              "grid grid-cols-3 gap-2"
            end
            
            div(class: grid_class) do
              # Display items in columns: 0,3,6 | 1,4,7 | 2,5,8
              num_columns.times do |col_index|
                div(class: "flex flex-col gap-1") do
                  3.times do |row_index|
                    item_index = col_index + (row_index * 3)
                    if item_index < items_to_show.length
                      item = items_to_show[item_index]
                      div(class: "text-sm text-muted-foreground") do
                        if item_index == 8 && items_count > 9
                          plain "...and #{items_count - 9} more"
                        else
                          "#{(item_index + 1)}. #{item["title"].to_s}"
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end

      def render_kind_badge
        case @checklist.kind
        when "template"
          Badge(variant: :lime) { "Template" }
        when "checklist"
          Badge(variant: :amber) { "Checklist" }
        end
      end

      def render_flow_badge
        case @checklist.flow
        when "sequential"
          Badge(variant: :cyan) { "Sequential" }
        when "parallel"
          Badge(variant: :rose) { "Parallel" }
        end
      end

      def render_edit_dialog
        render RubyUI::DialogContent.new(size: :lg) do
          render RubyUI::DialogHeader.new do
            render RubyUI::DialogTitle.new { "Edit Checklist Template" }
          end

          render RubyUI::DialogMiddle.new do
            render Components::Checklists::Form.new(checklist_template: @checklist)
          end
        end
      end

      def render_delete_confirmation_dialog
        render RubyUI::AlertDialog.new do
          render RubyUI::AlertDialogTrigger.new do
            Button(variant: :destructive, icon: true) do
              render Components::Icon.new(name: :delete, size: "12", class: "w-5 h-5")
            end
          end

          render RubyUI::AlertDialogContent.new do
            render RubyUI::AlertDialogHeader.new do
              render RubyUI::AlertDialogTitle.new { "Are you sure you want to delete #{@checklist.name}?" }
              render RubyUI::AlertDialogDescription.new { "This action cannot be undone. This will permanently delete the checklist template." }
            end

            render RubyUI::AlertDialogFooter.new(class: "mt-6 flex flex-row justify-end gap-3") do
              render RubyUI::AlertDialogCancel.new { "Cancel" }

              form(action: view_context.checklist_path(@checklist), method: "post", data: { turbo_method: :delete, action: "submit@document->ruby-ui--alert-dialog#dismiss" }, class: "inline", id: "delete_checklist_#{@checklist.id}") do
                input(type: :hidden, name: "authenticity_token", value: view_context.form_authenticity_token)
                input(type: :hidden, name: "_method", value: "delete")
                render RubyUI::AlertDialogAction.new(type: "submit", variant: :destructive) { "Delete" }
              end
            end
          end
        end
      end
    end
  end
end