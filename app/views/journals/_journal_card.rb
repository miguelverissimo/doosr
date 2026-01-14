# frozen_string_literal: true

module Views
  module Journals
    class JournalCard < ::Views::Base
      def initialize(journal:)
        @journal = journal
      end

      def view_template
        link_options = {
          href: view_context.journal_path(@journal),
          id: "journal_#{@journal.id}",
          class: "block p-4 bg-card border rounded-lg hover:bg-accent transition-colors"
        }

        # Disable Turbo cache for journal links when protection is enabled
        # This prevents showing cached unlocked content when session expires
        if view_context.current_user.journal_protection_enabled?
          link_options[:data] = {
            turbo_cache: false,
            turbo_prefetch: false,
            action: "click->nav-loader#show"
          }
        end

        a(**link_options) do
          div(class: "flex items-center justify-between") do
            div(class: "flex items-center gap-3") do
              render ::Components::Icon::Journal.new(size: "16", class: "text-primary")
              div do
                h3(class: "font-semibold") { @journal.date_display }
                p(class: "text-sm text-muted-foreground") do
                  render_journal_info
                end
              end
            end
            render ::Components::Icon::ChevronRight.new(size: "16", class: "text-muted-foreground")
          end
        end
      end

      private

      def render_journal_info
        prompts_text = "#{@journal.journal_prompts.count} prompts"

        if journal_locked?
          span(class: "flex items-center gap-1") do
            plain "#{prompts_text} · "
            render ::Components::Icon::Lock.new(size: "12", class: "inline")
          end
        else
          plain "#{prompts_text} · #{@journal.journal_fragments.count} entries"
        end
      end

      def journal_locked?
        view_context.current_user.journal_protection_enabled? && Current.encryption_key.nil?
      end
    end
  end
end
