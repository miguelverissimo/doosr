class ListsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_list, only: [:show, :edit, :update, :destroy]
  layout -> { Views::Layouts::AppLayout.new(pathname: request.path, list: @list) }

  def index
    @lists = current_user.lists.order(created_at: :desc)
    render Views::Lists::Index.new(lists: @lists)
  end

  def show
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

    render Views::Lists::Show.new(
      list: @list,
      tree: @tree,
      item_titles: @item_titles,
      is_owner: true
    )
  end

  def new
    @list = List.new
    render Views::Lists::New.new(list: @list)
  end

  def create
    @list = current_user.lists.build(list_params)

    if @list.save
      redirect_to @list, notice: "List created successfully"
    else
      render Views::Lists::New.new(list: @list), status: :unprocessable_entity
    end
  end

  def edit
    render Views::Lists::Edit.new(list: @list)
  end

  def update
    if @list.update(list_params)
      redirect_to @list, notice: "List updated successfully"
    else
      render Views::Lists::Edit.new(list: @list), status: :unprocessable_entity
    end
  end

  def destroy
    @list.destroy
    redirect_to lists_path, notice: "List deleted successfully"
  end

  private

  def set_list
    @list = current_user.lists.find(params[:id])
  end

  def list_params
    params.require(:list).permit(:title, :list_type, :visibility, :slug)
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
