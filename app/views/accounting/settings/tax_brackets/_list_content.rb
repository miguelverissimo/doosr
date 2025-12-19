module Views
  module Accounting
    module Settings
      module TaxBrackets
        class ListContent < Views::Base
          def initialize(user:, **attrs)
            @user = user
            @tax_brackets = ::Accounting::TaxBracket.where(user: @user)
            super(**attrs)
          end

          def view_template
            if @tax_brackets.empty?
              div(class: "flex h-full flex-col items-center justify-center") do
                p(class: "text-sm text-gray-500") { "No tax brackets found" }
              end
            else
              Table do
                TableHeader do
                  TableHead do
                    span(style: "font-size: 0.625rem; line-height: 1") { "ID" }
                  end
                  TableHead { "Name" }
                  TableHead { "Rate" }
                  TableHead { "Legal Reference" }
                  TableHead(class: "text-right") { "Actions" }
                end
                TableBody do
                  @tax_brackets.each do |tax_bracket|
                    render Views::Accounting::Settings::TaxBrackets::Row.new(tax_bracket: tax_bracket)
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

