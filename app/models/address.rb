class Address < ApplicationRecord
  belongs_to :user

  enum :address_type, {
    user: :user,
    client: :client,
    supplier: :supplier
  }, default: :user, validate: true

  enum :state, {
    active: :active,
    inactive: :inactive
  }, default: :active, validate: true

  # Validations
  validates :user, presence: true
  validates :address_type, presence: true
  validates :state, presence: true
  validates :name, presence: true
  validates :full_address, presence: true
  validates :country, presence: true
end
