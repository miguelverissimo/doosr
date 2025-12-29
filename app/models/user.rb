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
  has_many :lists, dependent: :destroy
  has_many :checklists, dependent: :destroy

  # Accounting
  has_many :addresses, class_name: "Address", dependent: :destroy
  has_many :accounting_items, class_name: "Accounting::AccountingItem", dependent: :destroy
  has_many :invoice_items, class_name: "Accounting::InvoiceItem", dependent: :destroy
  has_many :invoices, class_name: "Accounting::Invoice", dependent: :destroy
  has_many :invoice_templates, class_name: "Accounting::InvoiceTemplate", dependent: :destroy
  has_many :receipt_items, class_name: "Accounting::ReceiptItem", dependent: :destroy
  has_many :tax_brackets, class_name: "Accounting::TaxBracket", dependent: :destroy
  has_many :customers, class_name: "Accounting::Customer", dependent: :destroy
  has_many :accounting_logos, class_name: "Accounting::AccountingLogo", dependent: :destroy
  has_many :bank_infos, class_name: "Accounting::BankInfo", dependent: :destroy
  has_many :receipts, class_name: "Accounting::Receipt", dependent: :destroy
  has_many :receipt_receipt_items, class_name: "Accounting::ReceiptReceiptItem", dependent: :destroy

  # Settings defaults
  SETTINGS_DEFAULTS = {
    "theme" => "dark",
    "permanent_sections" => [],
    "day_migration_settings" => MigrationOptions.defaults
  }.freeze

  # Settings accessors
  def theme
    settings.fetch("theme", SETTINGS_DEFAULTS["theme"])
  end

  def theme=(value)
    settings["theme"] = value
    settings_will_change!
  end

  def permanent_sections
    settings.fetch("permanent_sections", SETTINGS_DEFAULTS["permanent_sections"])
  end

  def permanent_sections=(value)
    settings["permanent_sections"] = value
    settings_will_change!
  end

  def day_migration_settings
    settings.fetch("day_migration_settings", SETTINGS_DEFAULTS["day_migration_settings"])
  end

  def day_migration_settings=(value)
    settings["day_migration_settings"] = value
    settings_will_change!
  end

  # Ensure settings has default values
  after_initialize :ensure_settings_defaults

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_initialize.tap do |user|
      user.email = auth.info.email if user.email.blank?
      user.name = auth.info.name if user.respond_to?(:name) && user.name.blank?
      user.password ||= Devise.friendly_token[0, 20]
      user.save!
    end
  end

  private

  def ensure_settings_defaults
    self.settings ||= {}
    SETTINGS_DEFAULTS.each do |key, value|
      settings[key] ||= value
    end
  end
end
