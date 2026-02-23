# frozen_string_literal: true

module Components
  module ApiTokens
    class TokenRow < ::Components::Base
      def initialize(api_token:)
        @api_token = api_token
      end

      def view_template
        div(
          id: "api_token_#{@api_token.id}",
          class: "flex items-center justify-between p-3 bg-card border rounded-lg"
        ) do
          div(class: "flex-1 min-w-0") do
            div(class: "flex items-center gap-2") do
              render ::Components::Icon::Key.new(size: "16", class: "shrink-0 text-muted-foreground")
              span(class: "font-medium text-sm truncate") { @api_token.name }
            end
            div(class: "mt-2") do
              render_token_actions
              render_usage_meta
            end
          end

          render_delete_button
        end
      end

      private

      def render_token_actions
        token_value = @api_token.token

        if token_value.present?
          div(class: "flex items-center gap-2", data: { controller: "api-token-row" }) do
            render RubyUI::Clipboard.new(
              class: "flex-1 min-w-0 [&>div:first-child]:flex [&>div:first-child]:items-center [&>div:first-child]:gap-2"
            ) do
              render RubyUI::ClipboardSource.new(class: "flex-1 min-w-0") do
                render RubyUI::Input.new(
                  type: :password,
                  value: token_value,
                  readonly: true,
                  class: "font-mono text-xs w-full",
                  data: { api_token_row_target: "tokenInput" }
                )
              end

              render RubyUI::ClipboardTrigger.new(class: "shrink-0") do
                Button(variant: :outline, size: :sm, class: "shrink-0") do
                  render ::Components::Icon::Copy.new(size: "16")
                end
              end
            end

            Button(
              variant: :outline,
              size: :sm,
              class: "shrink-0",
              data: {
                action: "click->api-token-row#toggleReveal",
                api_token_row_target: "revealButton"
              }
            ) do
              render ::Components::Icon::Eye.new(size: "16")
              span(class: "ml-2", data: { api_token_row_target: "revealLabel" }) { "Reveal" }
            end
          end
        else
          div(class: "text-xs text-muted-foreground") do
            span(class: "font-mono") { "#{@api_token.token_prefix}..." }
            span(class: "ml-2") { "(only prefix available)" }
          end
        end
      end

      def render_usage_meta
        div(class: "mt-2 flex flex-wrap items-center gap-3 text-xs text-muted-foreground") do
          render_scope_badges
          if @api_token.last_used_at
            span { "Last used #{view_context.time_ago_in_words(@api_token.last_used_at)} ago" }
          else
            span { "Never used" }
          end
          span { "Created #{view_context.time_ago_in_words(@api_token.created_at)} ago" }
        end
      end

      def render_scope_badges
        if @api_token.scoped?
          @api_token.scopes.each do |scope|
            Badge(variant: :outline, size: :sm) { scope.titleize }
          end
        else
          Badge(variant: :secondary, size: :sm) { "Full access" }
        end
      end

      def render_delete_button
        render RubyUI::AlertDialog.new do
          render RubyUI::AlertDialogTrigger.new do
            Button(variant: :ghost, size: :sm) do
              render ::Components::Icon::Trash.new(size: "16", class: "text-destructive")
            end
          end

          render RubyUI::AlertDialogContent.new do
            render RubyUI::AlertDialogHeader.new do
              render RubyUI::AlertDialogTitle.new { "Revoke API Token" }
              render RubyUI::AlertDialogDescription.new do
                plain "Are you sure you want to revoke "
                strong { @api_token.name }
                plain "? Any applications using this token will lose access immediately. This cannot be undone."
              end
            end

            render RubyUI::AlertDialogFooter.new do
              render RubyUI::AlertDialogCancel.new { "Cancel" }
              render RubyUI::Form.new(
                action: view_context.api_token_path(@api_token),
                method: "post",
                class: "inline",
                data: { action: "submit@document->ruby-ui--alert-dialog#dismiss" }
              ) do
                render RubyUI::Input.new(
                  type: :hidden,
                  name: "authenticity_token",
                  value: view_context.form_authenticity_token
                )
                render RubyUI::Input.new(type: :hidden, name: "_method", value: "delete")
                Button(type: "submit", variant: :destructive) { "Revoke Token" }
              end
            end
          end
        end
      end
    end
  end
end
