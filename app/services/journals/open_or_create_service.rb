# frozen_string_literal: true

module Journals
  class OpenOrCreateService
    def self.call(user:, date:)
      new(user: user, date: date).call
    end

    def initialize(user:, date:)
      @user = user
      @date = date.is_a?(Date) ? date : Date.parse(date.to_s)
    end

    def call
      # Find or create journal
      journal = @user.journals.find_or_create_by!(date: @date)

      # Create scheduled prompts if any match
      result = ::Journals::CreatePromptsForDate.call(journal: journal, date: @date)

      {
        journal: journal,
        prompts_added: result[:prompts].any?
      }
    end
  end
end
