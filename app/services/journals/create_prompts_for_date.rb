# frozen_string_literal: true

module Journals
  class CreatePromptsForDate
    def self.call(journal:, date:)
      new(journal: journal, date: date).call
    end

    def initialize(journal:, date:)
      @journal = journal
      @date = date
      @user = journal.user
    end

    def call
      created_prompts = []

      # Get all active templates for the user
      templates = ::JournalPromptTemplate.for_user(@user).active

      # Filter templates that should appear on this date
      templates.each do |template|
        next unless template.scheduled_for_date?(@date)

        # Check if this prompt already exists in the journal
        existing_prompt = @journal.journal_prompts.find_by(prompt_text: template.prompt_text)
        next if existing_prompt.present?

        # Create the prompt
        prompt = @journal.journal_prompts.create!(
          user: @user,
          prompt_text: template.prompt_text
        )

        # Add to journal's descendant
        @journal.descendant.add_active_record("JournalPrompt", prompt.id)
        @journal.descendant.save!

        created_prompts << prompt
      end

      { prompts: created_prompts }
    end
  end
end
