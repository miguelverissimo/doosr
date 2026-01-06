# frozen_string_literal: true

module Views
  module Notes
    class List < ::Views::Base
      def initialize(notes:, search_query: nil, page: 1)
        @notes = notes
        @search_query = search_query
        @page = page
      end

      def view_template
        div(class: "flex flex-col gap-4", id: "notes_filter_section", data: { controller: "note-search" }) do
          # Turbo frame for lazy-loaded dialogs
          turbo_frame_tag "note_dialog"

          # Header with title and create button
          div(class: "flex items-center justify-between mb-4") do
            div do
              h1(class: "text-2xl font-bold") { "Notes" }
              p(class: "text-sm text-muted-foreground") { "All your notes in one place" }
            end
            render ::Components::ColoredLink.new(
              href: view_context.new_note_path,
              variant: :primary,
              data: { turbo_stream: true }
            ) { "New Note" }
          end

          # Search form
          render_search_form

          # Loading spinner (hidden by default)
          div(
            id: "notes_loading_spinner",
            class: "hidden",
            data: { note_search_target: "spinner" }
          ) do
            render ::Components::Shared::LoadingSpinner.new(message: "Loading notes...")
          end

          # Note content
          div(data: { note_search_target: "content" }) do
            render ::Views::Notes::ListContent.new(
              notes: @notes,
              search_query: @search_query,
              page: @page
            )
          end
        end
      end

      private

      def render_search_form
        form(
          action: view_context.notes_path,
          method: "get",
          data: {
            turbo_stream: true,
            action: "submit->note-search#showSpinner"
          },
          class: "mb-4"
        ) do
          div(class: "flex gap-2") do
            div(class: "flex-1") do
              render RubyUI::Input.new(
                type: :text,
                name: "search_query",
                placeholder: "Search notes by content...",
                value: @search_query
              )
            end

            div(class: "flex gap-2") do
              Button(variant: :primary, type: :submit) { "Search" }
              if @search_query.present?
                render ::Components::ColoredLink.new(
                  href: view_context.notes_path,
                  variant: :outline,
                  data: {
                    turbo_stream: true,
                    action: "click->note-search#showSpinner"
                  }
                ) { "Clear" }
              end
            end
          end
        end
      end
    end
  end
end
