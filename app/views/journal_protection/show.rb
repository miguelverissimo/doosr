# frozen_string_literal: true

module Views
  module JournalProtection
    class Show < ::Views::Base
      def initialize(user:)
        @user = user
      end

      def view_template
        div(id: "journal_protection_content", class: "flex h-full flex-col p-4") do
          div(class: "rounded-lg border p-4 md:p-6 space-y-4 bg-background text-foreground") do
            div(class: "flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2 mb-4") do
              h1(class: "text-xl font-bold") { "Journal Protection" }
            end

            p(class: "text-muted-foreground mb-4") do
              plain "Protect your journal entries with a password. "
              plain "Your entries will be encrypted and only visible after entering your password."
            end

            if @user.journal_protection_enabled?
              render_protection_enabled
            else
              render_protection_disabled
            end
          end

          render_back_link
        end
      end

      private

      def render_protection_enabled
        div(class: "space-y-4") do
          div(class: "flex items-center gap-2") do
            Badge(variant: :success) do
              render ::Components::Icon::Lock.new(size: "14", class: "mr-1")
              plain "Protected"
            end
          end

          p(class: "text-sm text-muted-foreground") do
            plain "Your journal entries are encrypted and protected with a password."
          end

          div(class: "flex flex-wrap gap-2 mt-4") do
            Button(
              variant: :outline,
              data: {
                controller: "enable-dialog",
                action: "click->enable-dialog#openDialog",
                enable_dialog_url_value: journal_protection_settings_path(action_type: "change_password")
              }
            ) do
              render ::Components::Icon::Key.new(size: "16", class: "mr-2")
              plain "Change Password"
            end

            Button(
              variant: :destructive,
              data: {
                controller: "enable-dialog",
                action: "click->enable-dialog#openDialog",
                enable_dialog_url_value: journal_protection_settings_path(action_type: "disable")
              }
            ) do
              render ::Components::Icon::LockOpen.new(size: "16", class: "mr-2")
              plain "Disable Protection"
            end
          end
        end
      end

      def render_protection_disabled
        div(class: "space-y-4") do
          div(class: "flex items-center gap-2") do
            Badge(variant: :secondary) do
              render ::Components::Icon::LockOpen.new(size: "14", class: "mr-1")
              plain "Not Protected"
            end
          end

          p(class: "text-sm text-muted-foreground") do
            plain "Your journal entries are not currently protected. "
            plain "Enable protection to encrypt your entries with a password."
          end

          div(class: "mt-4") do
            Button(
              variant: :primary,
              data: {
                controller: "enable-dialog",
                action: "click->enable-dialog#openDialog",
                enable_dialog_url_value: journal_protection_settings_path(action_type: "enable")
              }
            ) do
              render ::Components::Icon::Lock.new(size: "16", class: "mr-2")
              plain "Enable Protection"
            end
          end
        end
      end

      def render_back_link
        div(class: "mt-4") do
          render ::Components::ColoredLink.new(
            href: authenticated_root_path,
            variant: :ghost,
            size: :sm
          ) do
            render ::Components::Icon::ArrowLeft.new(size: "16", class: "mr-1")
            plain "Back to Day"
          end
        end
      end
    end
  end
end
