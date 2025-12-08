class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable
  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :omniauthable,
         omniauth_providers: %i[google_oauth2 github]

  # Associations
  has_many :days, dependent: :destroy
  has_many :items, dependent: :destroy

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_initialize.tap do |user|
      user.email = auth.info.email if user.email.blank?
      user.name = auth.info.name if user.respond_to?(:name) && user.name.blank?
      user.password ||= Devise.friendly_token[0, 20]
      user.save!
    end
  end
end
