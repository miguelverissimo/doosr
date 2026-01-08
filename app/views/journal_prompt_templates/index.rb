# frozen_string_literal: true

module Views
  module JournalPromptTemplates
    class Index < ::Views::Base
      def initialize(templates:)
        @templates = templates
      end

      def view_template
        div(class: "flex h-full flex-col p-4") do
          # Header
          div(class: "flex items-center justify-between mb-6") do
            div do
              h1(class: "text-2xl font-bold") { "Journal Prompts" }
              p(class: "text-sm text-muted-foreground") { "Create reusable prompts with scheduling" }
            end
            Button(
              variant: :primary,
              data: {
                controller: "journal-template",
                action: "click->journal-template#openDialog"
              }
            ) { "New Prompt" }
          end

          # Templates list
          if @templates.empty?
            div(class: "flex h-full flex-col items-center justify-center") do
              p(class: "text-sm text-muted-foreground") { "No prompts yet. Create your first one!" }
            end
          else
            div(id: "templates_list", class: "space-y-2") do
              @templates.each do |template|
                render ::Views::JournalPromptTemplates::TemplateRow.new(template: template)
              end
            end
          end
        end
      end
    end
  end
end
