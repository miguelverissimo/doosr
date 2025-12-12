class ListsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_list, only: [:show, :edit, :update, :destroy]
  layout -> { Views::Layouts::AppLayout.new(pathname: request.path) }

  def index
    @lists = current_user.lists.order(created_at: :desc)
    render Views::Lists::Index.new(lists: @lists)
  end

  def show
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

    render Views::Lists::Show.new(
      list: @list,
      all_items: @all_items,
      active_items: @active_items,
      inactive_items: @inactive_items,
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
