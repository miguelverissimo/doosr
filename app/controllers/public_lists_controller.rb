class PublicListsController < ApplicationController
  before_action :set_list
  layout -> { Views::Layouts::AuthLayout.new }

  def show
    # Only public lists can be viewed via this controller
    unless @list.list_type_public_list?
      redirect_to unauthenticated_root_path, alert: "List not found or not public"
      return
    end

    # Fetch all items recursively if list has descendant
    if @list.descendant
      items_data = fetch_list_items(@list)
      @all_items = items_data[:all_items]
      @active_items = items_data[:active_items]
      @inactive_items = items_data[:inactive_items]

      # Extract titles for autocomplete (only from top-level list items, not nested)
      list_item_ids = @list.descendant.active_items + @list.descendant.inactive_items
      list_items = Item.where(id: list_item_ids)
      @item_titles = list_items.map(&:title).uniq.sort
    else
      @item_titles = []
    end

    # Check if current user is the owner
    is_owner = user_signed_in? && @list.user_id == current_user.id

    render Views::Lists::PublicShow.new(
      list: @list,
      all_items: @all_items,
      active_items: @active_items,
      inactive_items: @inactive_items,
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

  def fetch_list_items(list)
    return { all_items: [], active_items: [], inactive_items: [] } unless list.descendant

    descendant = list.descendant
    all_item_ids = descendant.all_items

    # Fetch all items - convert to array
    all_items = Item.where(id: all_item_ids).includes(:descendant, :user).to_a

    # Build item lookup
    items_by_id = all_items.index_by(&:id)

    # Order items by their position in arrays
    active_items = descendant.active_items.map { |id| items_by_id[id] }.compact
    inactive_items = descendant.inactive_items.map { |id| items_by_id[id] }.compact

    # Recursively fetch nested items
    all_items.each do |item|
      if item.descendant
        nested_data = fetch_nested_items(item)
        all_items.concat(nested_data[:all_items])
        active_items.concat(nested_data[:active_items])
        inactive_items.concat(nested_data[:inactive_items])
      end
    end

    {
      all_items: all_items,
      active_items: active_items,
      inactive_items: inactive_items
    }
  end

  def fetch_nested_items(parent_item)
    return { all_items: [], active_items: [], inactive_items: [] } unless parent_item.descendant

    descendant = parent_item.descendant
    all_item_ids = descendant.all_items

    all_items = Item.where(id: all_item_ids).includes(:descendant, :user).to_a
    items_by_id = all_items.index_by(&:id)

    active_items = descendant.active_items.map { |id| items_by_id[id] }.compact
    inactive_items = descendant.inactive_items.map { |id| items_by_id[id] }.compact

    # Recurse for nested items
    all_items.each do |item|
      if item.descendant
        nested_data = fetch_nested_items(item)
        all_items.concat(nested_data[:all_items])
        active_items.concat(nested_data[:active_items])
        inactive_items.concat(nested_data[:inactive_items])
      end
    end

    {
      all_items: all_items,
      active_items: active_items,
      inactive_items: inactive_items
    }
  end
end
