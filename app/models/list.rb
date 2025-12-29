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
    item_ids = descendant.extract_active_item_ids + descendant.extract_inactive_item_ids
    return [] if item_ids.empty?
    Item.where(id: item_ids)
  end

  def active_items
    return [] unless descendant
    item_ids = descendant.extract_active_item_ids
    return [] if item_ids.empty?
    # Use sanitize_sql to prevent SQL injection
    order_sql = ActiveRecord::Base.sanitize_sql_array(
      ["array_position(ARRAY[?]::integer[], id)", item_ids.map(&:to_i)]
    )
    Item.where(id: item_ids).order(Arel.sql(order_sql))
  end

  def inactive_items
    return [] unless descendant
    item_ids = descendant.extract_inactive_item_ids
    return [] if item_ids.empty?
    # Use sanitize_sql to prevent SQL injection
    order_sql = ActiveRecord::Base.sanitize_sql_array(
      ["array_position(ARRAY[?]::integer[], id)", item_ids.map(&:to_i)]
    )
    Item.where(id: item_ids).order(Arel.sql(order_sql))
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
