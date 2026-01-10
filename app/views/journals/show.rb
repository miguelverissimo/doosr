# frozen_string_literal: true

module Views
  module Journals
    class Show < ::Views::Base
      def initialize(journal:, tree:)
        @journal = journal
        @tree = tree
      end

      def view_template
        div(class: "flex h-full flex-col p-4", data: { controller: "journal", journal_journal_id_value: @journal.id }) do
          # Header
          div(class: "mb-6") do
            div(class: "flex items-center justify-between mb-2") do
              a(
                href: view_context.journals_path,
                class: "text-sm text-muted-foreground hover:text-foreground flex items-center gap-1"
              ) do
                render ::Components::Icon::ChevronLeft.new(size: "12")
                plain "Back to Journals"
              end

              div(class: "flex gap-2") do
                render RubyUI::AlertDialog.new do
                  render RubyUI::AlertDialogTrigger.new do
                    Button(variant: :destructive, size: :sm) { "Delete Journal" }
                  end

                  render RubyUI::AlertDialogContent.new do
                    render RubyUI::AlertDialogHeader.new do
                      render RubyUI::AlertDialogTitle.new { "Are you sure you want to delete this journal?" }
                      render RubyUI::AlertDialogDescription.new { "This action cannot be undone. This will permanently delete the journal and all its entries." }
                    end

                    render RubyUI::AlertDialogFooter.new(class: "mt-6 flex flex-row justify-end gap-3") do
                      render RubyUI::AlertDialogCancel.new { "Cancel" }

                      form(
                        action: view_context.journal_path(@journal),
                        method: "post",
                        data: { turbo_method: :delete, turbo_stream: true, action: "submit@document->ruby-ui--alert-dialog#dismiss" },
                        class: "inline"
                      ) do
                        csrf_token_field
                        input(type: :hidden, name: "_method", value: "delete")
                        render RubyUI::AlertDialogAction.new(type: "submit", variant: :destructive) { "Delete" }
                      end
                    end
                  end
                end
              end
            end

            h1(class: "text-3xl font-bold") { @journal.date_display }
          end

          # Actions
          div(class: "flex gap-2 mb-6") do
            Button(
              variant: :primary,
              size: :sm,
              data: { action: "click->journal#newFragment" }
            ) do
              render ::Components::Icon::Add.new(size: "12")
              span(class: "ml-1") { "Add Entry" }
            end
          end

          # Journal tree
          div(id: "journal_tree", class: "flex-1") do
            render ::Views::Journals::JournalTree.new(journal: @journal, tree: @tree)
          end
        end
      end
    end
  end
end
