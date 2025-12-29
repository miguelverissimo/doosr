module Views
  module Accounting
    module Settings
      module Logos
        class ListContents < ::Views::Base
          def initialize(user:)
            @user = user
            @accounting_logos = user.accounting_logos
          end

          def view_template
            turbo_frame_tag "accounting_logos_content" do
              if @accounting_logos.empty?
                div(class: "flex h-full flex-col items-center justify-center") do
                  p(class: "text-sm text-gray-500") { "No logos found" }
                end
              else
                @accounting_logos.each do |accounting_logo|
                  div(id: "accounting_logo_#{accounting_logo.id}_div", class: "mt-2") do
                    render ::Views::Accounting::Settings::Logos::LogoRow.new(accounting_logo: accounting_logo)
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