class PublicListsController < ApplicationController
  before_action :set_list
  layout -> { ::Views::Layouts::AuthLayout.new }

  def show
    # Only public lists can be viewed via this controller
    unless @list.list_type_public_list?
      redirect_to unauthenticated_root_path, alert: "List not found or not public"
      return
    end

    # Build tree using ItemTree::Build
    if @list.descendant
      @tree = ItemTree::Build.call(@list.descendant, root_label: "list")

      # Extract titles for autocomplete (ALL items in the list, including nested)
      all_item_ids = find_all_list_item_ids_recursively(@list)
      all_items = Item.where(id: all_item_ids)
      @item_titles = all_items.map(&:title).uniq.sort
    else
      @tree = nil
      @item_titles = []
    end

    # Check if current user is the owner
    is_owner = user_signed_in? && @list.user_id == current_user.id

    render ::Views::Lists::PublicShow.new(
      list: @list,
      tree: @tree,
      item_titles: @item_titles,
      is_owner: is_owner,
      is_editable: @list.visibility_editable?
    )
  end

  private

  def set_list
    @list = List.find_by!(slug: params[:slug])
  rescue ActiveRecord::RecordNotFound
    redirect_to unauthenticated_root_path, alert: "List not found"
  end

  # Recursively find all item IDs in a list, including nested items
  def find_all_list_item_ids_recursively(list)
    return [] unless list.descendant

    item_ids = []
    descendant = list.descendant

    # Get direct items (extract IDs from tuples)
    direct_item_ids = descendant.extract_active_item_ids + descendant.extract_inactive_item_ids
    item_ids.concat(direct_item_ids)

    # Get all items to check for nested descendants
    items = Item.where(id: direct_item_ids).includes(:descendant)

    # Recursively get nested items
    items.each do |item|
      if item.descendant
        nested_ids = find_all_item_ids_recursively_from_item(item)
        item_ids.concat(nested_ids)
      end
    end

    item_ids.uniq
  end

  # Helper to recursively find item IDs from an item's descendant
  def find_all_item_ids_recursively_from_item(item)
    return [] unless item.descendant

    item_ids = []
    descendant = item.descendant

    # Get direct nested items (extract IDs from tuples)
    nested_item_ids = descendant.extract_active_item_ids + descendant.extract_inactive_item_ids
    item_ids.concat(nested_item_ids)

    # Get all nested items to check for further nesting
    nested_items = Item.where(id: nested_item_ids).includes(:descendant)

    # Recursively get nested items
    nested_items.each do |nested_item|
      if nested_item.descendant
        deeper_ids = find_all_item_ids_recursively_from_item(nested_item)
        item_ids.concat(deeper_ids)
      end
    end

    item_ids.uniq
  end
end
