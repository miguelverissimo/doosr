# frozen_string_literal: true

module Views
  module Journals
    class List < ::Views::Base
      def initialize(journals:, search_query: nil, page: 1)
        @journals = journals
        @search_query = search_query
        @page = page
      end

      def view_template
        div(class: "flex flex-col gap-4", id: "journals_filter_section", data: { controller: "journal-search" }) do
          # Turbo frame for lazy-loaded dialogs
          turbo_frame_tag "journal_dialog"

          # Header with title and create button
          div(class: "flex items-center justify-between mb-4") do
            div do
              h1(class: "text-2xl font-bold") { "Journals" }
              p(class: "text-sm text-muted-foreground") { "Your daily journal entries" }
            end
            div(class: "flex gap-2") do
              Button(
                variant: :outline,
                href: view_context.journal_prompt_templates_path,
                data: { action: "click->nav-loader#show" }
              ) do
                render ::Components::Icon.new(name: :settings, size: "12")
                plain "Manage Prompts"
              end
              Button(
                variant: :primary,
                data: {
                  controller: "journal-new",
                  action: "click->journal-new#openDialog"
                }
              ) { "New Journal" }
            end
          end

          # Search form
          render_search_form

          # Loading spinner (hidden by default)
          div(
            id: "journals_loading_spinner",
            class: "hidden",
            data: { journal_search_target: "spinner" }
          ) do
            render ::Components::Shared::LoadingSpinner.new(message: "Loading journals...")
          end

          # Journal content
          div(data: { journal_search_target: "content" }) do
            render ::Views::Journals::ListContent.new(
              journals: @journals,
              search_query: @search_query,
              page: @page
            )
          end
        end
      end

      private

      def render_search_form
        form(
          action: view_context.journals_path,
          method: "get",
          data: {
            turbo_stream: true,
            action: "submit->journal-search#showSpinner"
          },
          class: "mb-4"
        ) do
          div(class: "flex gap-2") do
            div(class: "flex-1") do
              render RubyUI::Input.new(
                type: :text,
                name: "search_query",
                placeholder: "Search journals by date...",
                value: @search_query
              )
            end

            div(class: "flex gap-2") do
              Button(variant: :primary, type: :submit) { "Search" }
              if @search_query.present?
                render ::Components::ColoredLink.new(
                  href: view_context.journals_path,
                  variant: :outline,
                  data: {
                    turbo_stream: true,
                    action: "click->journal-search#showSpinner"
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
