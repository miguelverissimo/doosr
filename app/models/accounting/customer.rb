module Accounting
  class Customer < ApplicationRecord
    belongs_to :user
    belongs_to :address

    validates :name, presence: true
    validates :user, presence: true
    validates :address, presence: true
    validates :name, uniqueness: { scope: :user_id }
  end
end
