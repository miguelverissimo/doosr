# frozen_string_literal: true

# This file exists solely to ensure Tailwind CSS includes dynamically generated classes
# These classes are used in InvoiceRow but generated via string interpolation
# DO NOT DELETE THIS FILE - it's needed for Tailwind's content scanning

module Views
  module Accounting
    module Invoices
      class Safelist < ::Views::Base
        def view_template
          # These classes are dynamically generated in InvoiceRow#row_color and InvoiceRow#currency_color
          # They need to be present here so Tailwind's scanner includes them in the bundle
          div(class: "!bg-muted hover:!bg-muted/50")
          div(class: "!bg-secondary hover:!bg-secondary/50")
          div(class: "!bg-accent hover:!bg-accent/50")
          div(class: "!bg-destructive hover:!bg-destructive/50")
          div(class: "text-green-500")
          div(class: "text-blue-500")
          div(class: "text-red-500")
        end
      end
    end
  end
end
