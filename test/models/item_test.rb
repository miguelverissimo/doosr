require "test_helper"

class ItemTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @item = items(:completable_one)
  end

  test "should be valid" do
    assert @item.valid?
  end

  test "should require title" do
    item = Item.new(user: @user, item_type: :completable)
    assert_not item.valid?
    assert_includes item.errors[:title], "can't be blank"
  end

  test "should require user" do
    item = Item.new(title: "Test", item_type: :completable)
    assert_not item.valid?
  end

  test "completable items can be marked as done" do
    assert @item.completable?
    assert @item.mark_done!
    assert @item.done?
    assert_not_nil @item.done_at
  end

  test "section items cannot be completed" do
    section = items(:section_one)
    assert section.section?
    assert_not section.mark_done!
  end

  test "items can be dropped" do
    assert @item.mark_dropped!
    assert @item.dropped?
    assert_not_nil @item.dropped_at
  end

  test "items can be deferred" do
    future_date = 1.week.from_now
    assert @item.mark_deferred!(future_date)
    assert @item.deferred?
    assert_not_nil @item.deferred_at
    assert_equal future_date, @item.deferred_to
  end

  test "items can be returned to todo state" do
    @item.mark_done!
    assert @item.done?

    assert @item.mark_todo!
    assert @item.todo?
    assert_nil @item.done_at
  end
end
