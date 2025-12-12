class List < ApplicationRecord
  belongs_to :user
  belongs_to :descendant, optional: true

  enum :list_type, { private_list: 0, public_list: 1, shared_list: 2 }, prefix: true
  enum :visibility, { read_only: 0, editable: 1 }, prefix: true

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :list_type, presence: true
  validates :visibility, presence: true

  # Slug is only used for public lists, but we'll always generate one
  before_validation :generate_slug, on: :create, if: -> { slug.blank? }

  # Create descendant after list is created
  after_create :create_list_descendant

  def items
    return [] unless descendant
    Item.where(id: descendant.all_items)
  end

  def active_items
    return [] unless descendant
    Item.where(id: descendant.active_items).order(Arel.sql("array_position(ARRAY[#{descendant.active_items.join(',')}]::integer[], id)"))
  end

  def inactive_items
    return [] unless descendant
    Item.where(id: descendant.inactive_items).order(Arel.sql("array_position(ARRAY[#{descendant.inactive_items.join(',')}]::integer[], id)"))
  end

  def public_url
    return nil unless list_type_public_list?
    "/p/lists/#{slug}"
  end

  private

  def generate_slug
    require 'ulid'
    self.slug = ULID.generate.downcase
  end

  def create_list_descendant
    self.descendant = Descendant.create!(descendable: self)
    save!
  end
end
