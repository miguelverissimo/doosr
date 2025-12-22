module Accounting
  class FiscalInfo < ApplicationRecord
    belongs_to :user
    belongs_to :address, class_name: "Address", optional: true

    enum :kind, {
      provider: :provider,
      customer: :customer
    }, default: :provider, validate: true

    validates :title, presence: true
    validates :tax_number, presence: true
  end
end
