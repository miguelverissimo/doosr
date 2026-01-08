# frozen_string_literal: true

module Views
  module Journals
    class FragmentItem < ::Views::Base
      def initialize(fragment:)
        @fragment = fragment
      end

      def view_template
        div(
          id: "journal_fragment_#{@fragment.id}",
          class: "p-4 bg-card border rounded-lg hover:shadow-sm transition-shadow"
        ) do
          div(class: "flex items-start gap-3") do
            render ::Components::Icon.new(name: :journal_entry, size: "16", class: "text-muted-foreground mt-1")

            div(class: "flex-1 min-w-0") do
              div(class: "prose prose-sm dark:prose-invert max-w-none") do
                raw @fragment.rendered_markdown
              end

              div(class: "flex gap-2 mt-3") do
                Button(
                  variant: :secondary,
                  size: :sm,
                  icon: true,
                  data: {
                    controller: "journal-fragment",
                    journal_fragment_url_value: view_context.edit_journal_fragment_path(@fragment),
                    action: "click->journal-fragment#openDialog"
                  }
                ) do
                  render ::Components::Icon.new(name: :edit, size: "12")
                end

                render RubyUI::AlertDialog.new do
                  render RubyUI::AlertDialogTrigger.new do
                    Button(variant: :destructive, size: :sm, icon: true) do
                      render ::Components::Icon.new(name: :delete, size: "12")
                    end
                  end

                  render RubyUI::AlertDialogContent.new do
                    render RubyUI::AlertDialogHeader.new do
                      render RubyUI::AlertDialogTitle.new { "Delete this entry?" }
                      render RubyUI::AlertDialogDescription.new { "This action cannot be undone." }
                    end

                    render RubyUI::AlertDialogFooter.new(class: "mt-6 flex flex-row justify-end gap-3") do
                      render RubyUI::AlertDialogCancel.new { "Cancel" }

                      form(
                        action: view_context.journal_fragment_path(@fragment),
                        method: "post",
                        data: { turbo_stream: true, action: "submit@document->ruby-ui--alert-dialog#dismiss" },
                        class: "inline"
                      ) do
                        csrf_token_field
                        input(type: "hidden", name: "_method", value: "delete")
                        render RubyUI::AlertDialogAction.new(type: "submit", variant: :destructive) { "Delete" }
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
  end
end
