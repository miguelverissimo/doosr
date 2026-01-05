# frozen_string_literal: true

module Views
  module Admin
    module Users
      class UserRow < ::Views::Base
        def initialize(user:)
          @user = user
        end

        def view_template
          div(
            id: "user_#{@user.id}",
            class: "grid grid-cols-12 gap-4 p-4 items-center hover:bg-muted/30 transition-colors"
          ) do
            # Name
            div(class: "col-span-3") do
              p(class: "font-medium") { @user.name.presence || "—" }
            end

            # Email
            div(class: "col-span-3") do
              p(class: "text-sm text-muted-foreground") { @user.email }
            end

            # Access Confirmed Checkbox
            div(class: "col-span-2 flex justify-center") do
              render_access_checkbox
            end

            # Roles Combobox
            div(class: "col-span-4") do
              render_roles_combobox
            end
          end
        end

        private

        def render_access_checkbox
          form(
            action: toggle_access_admin_user_path(@user),
            method: "post",
            data: {
              controller: "form-loading admin-user-access",
              form_loading_message_value: "Updating access...",
              action: "change->admin-user-access#toggle"
            },
            class: "shrink-0"
          ) do
            csrf_token_field
            input(type: "hidden", name: "_method", value: "patch")

            label(class: "flex items-center justify-center cursor-pointer") do
              input(
                type: "checkbox",
                checked: @user.access_confirmed,
                class: "w-4 h-4 rounded border-gray-300 cursor-pointer"
              )
            end
          end
        end

        def render_roles_combobox
          div(
            data: {
              controller: "admin-user-roles",
              admin_user_roles_user_id_value: @user.id,
              admin_user_roles_selected_value: @user.roles.to_json
            }
          ) do
            Combobox(term: "roles") do
              ComboboxTrigger(placeholder: "Select roles")

              ComboboxPopover do
                ComboboxSearchInput(placeholder: "Search roles...")

                ComboboxList do
                  ComboboxEmptyState { "No roles found" }

                  ::User::AVAILABLE_ROLES.each do |role|
                    ComboboxItem do
                      ComboboxCheckbox(
                        name: "roles[]",
                        value: role,
                        checked: @user.roles.include?(role),
                        data: { action: "change->admin-user-roles#updateRoles" }
                      )
                      span { role.humanize }
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
