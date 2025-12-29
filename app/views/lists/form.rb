# frozen_string_literal: true

module Views
  module Lists
    class Form < ::Views::Base
      def initialize(list:, action:)
        @list = list
        @action = action
      end

      def view_template
        form(
          action: @action,
          method: @list.persisted? ? "patch" : "post",
          class: "space-y-6"
        ) do
          csrf_token_field

          # Title field
          div(class: "space-y-2") do
            label(for: "list_title", class: "text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70") do
              plain "Title"
            end
            Input(
              type: "text",
              id: "list_title",
              name: "list[title]",
              value: @list.title,
              placeholder: "My Shopping List",
              required: true,
              class: "w-full"
            )
            if @list.errors[:title].any?
              p(class: "text-sm text-destructive") { @list.errors[:title].first }
            end
          end

          # List type field
          div(class: "space-y-2") do
            label(for: "list_list_type", class: "text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70") do
              plain "Type"
            end
            select(
              id: "list_list_type",
              name: "list[list_type]",
              class: "flex h-10 w-full items-center justify-between rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
            ) do
              option(value: "private_list", selected: @list.list_type == "private_list") { "Private" }
              option(value: "public_list", selected: @list.list_type == "public_list") { "Public" }
              option(value: "shared_list", selected: @list.list_type == "shared_list") { "Shared" }
            end
            p(class: "text-xs text-muted-foreground") do
              plain "Private: only you can view. Public: accessible via slug without auth. Shared: accessible to specific users."
            end
            if @list.errors[:list_type].any?
              p(class: "text-sm text-destructive") { @list.errors[:list_type].first }
            end
          end

          # Visibility field
          div(class: "space-y-2") do
            label(for: "list_visibility", class: "text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70") do
              plain "Visibility (for non-owners)"
            end
            select(
              id: "list_visibility",
              name: "list[visibility]",
              class: "flex h-10 w-full items-center justify-between rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
            ) do
              option(value: "read_only", selected: @list.visibility == "read_only") { "Read Only" }
              option(value: "editable", selected: @list.visibility == "editable") { "Editable" }
            end
            p(class: "text-xs text-muted-foreground") do
              plain "Read only: others can only view. Editable: others can modify items."
            end
            if @list.errors[:visibility].any?
              p(class: "text-sm text-destructive") { @list.errors[:visibility].first }
            end
          end

          # Slug field (only for public lists, but always show for now)
          div(class: "space-y-2") do
            label(for: "list_slug", class: "text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70") do
              plain "Slug (for public URLs)"
            end
            Input(
              type: "text",
              id: "list_slug",
              name: "list[slug]",
              value: @list.slug,
              placeholder: "my-shopping-list",
              class: "w-full font-mono text-sm"
            )
            p(class: "text-xs text-muted-foreground") do
              plain "Leave blank to auto-generate a random slug. Public lists are accessible at /p/lists/[slug]"
            end
            if @list.errors[:slug].any?
              p(class: "text-sm text-destructive") { @list.errors[:slug].first }
            end
          end

          # Submit button
          div(class: "flex items-center gap-2") do
            Button(type: :submit, variant: :primary) do
              @list.persisted? ? "Update List" : "Create List"
            end
            Button(
              href: @list.persisted? ? list_path(@list) : lists_path,
              variant: :outline
            ) do
              plain "Cancel"
            end
          end
        end
      end
    end
  end
end
