# frozen_string_literal: true

module Views
  module Journals
    class Locked < ::Views::Base
      def initialize(journal:)
        @journal = journal
      end

      def view_template
        div(
          id: "journal_content",
          class: "flex h-full flex-col p-4",
          data: { controller: "journal-unlock" }
        ) do
          div(class: "mb-6") do
            div(class: "flex items-center justify-between mb-2") do
              a(
                href: view_context.journals_path,
                class: "text-sm text-muted-foreground hover:text-foreground flex items-center gap-1"
              ) do
                render ::Components::Icon::ChevronLeft.new(size: "12")
                plain "Back to Journals"
              end
            end

            h1(class: "text-3xl font-bold") { @journal.date_display }
          end

          div(class: "flex flex-col items-center justify-center flex-1 space-y-4") do
            div(class: "p-4 rounded-full bg-muted") do
              render ::Components::Icon::Lock.new(size: "48", class: "text-muted-foreground")
            end

            h2(class: "text-xl font-semibold text-muted-foreground") { "Journal is Locked" }

            p(class: "text-sm text-muted-foreground text-center max-w-md") do
              plain "This journal is protected. Enter your password to view its contents."
            end

            Button(
              variant: :primary,
              data: { action: "click->journal-unlock#openUnlockDialog" }
            ) do
              render ::Components::Icon::LockOpen.new(size: "16")
              span(class: "ml-2") { "Unlock Journal" }
            end
          end
        end
      end
    end
  end
end
