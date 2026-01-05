# frozen_string_literal: true

module Views
  module Admin
    module Users
      class Index < ::Views::Base
        def initialize(users:)
          @users = users
        end

        def view_template
          div(class: "container mx-auto p-6 max-w-7xl") do
            # Header
            div(class: "mb-8") do
              h1(class: "text-3xl font-bold") { "User Management" }
              p(class: "text-muted-foreground mt-2") do
                plain "Manage user access and roles"
              end
            end

            # Users Table
            div(class: "rounded-lg border border-border") do
              # Table Header
              div(class: "grid grid-cols-12 gap-4 p-4 border-b border-border bg-muted/50 font-semibold text-sm") do
                div(class: "col-span-3") { "Name" }
                div(class: "col-span-3") { "Email" }
                div(class: "col-span-2 text-center") { "Access" }
                div(class: "col-span-4") { "Roles" }
              end

              # Table Body
              div(class: "divide-y divide-border") do
                if @users.any?
                  @users.each do |user|
                    render ::Views::Admin::Users::UserRow.new(user: user)
                  end
                else
                  div(class: "p-8 text-center text-muted-foreground") do
                    plain "No users found"
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
