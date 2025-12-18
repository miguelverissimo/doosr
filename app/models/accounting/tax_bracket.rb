module Accounting
  class TaxBracket < ApplicationRecord
    # Associations
    belongs_to :user

    # Validations
    validates :name, :percentage, presence: true
    validates :user, presence: true
    validates :name, uniqueness: { scope: :user_id }
  end
end