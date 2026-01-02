require "test_helper"

class ItemTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "test@example.com", password: "password123", password_confirmation: "password123")
    @item = @user.items.create!(title: "Test Item", item_type: :completable, state: :todo)
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
    assert @item.set_done!
    assert @item.done?
    assert_not_nil @item.done_at
  end

  test "section items cannot be completed" do
    section = @user.items.create!(title: "Section", item_type: :section, state: :todo)
    assert section.section?
    assert_not section.set_done!
  end

  test "items can be dropped" do
    assert @item.set_dropped!
    assert @item.dropped?
    assert_not_nil @item.dropped_at
  end

  test "items can be deferred" do
    # Round to microsecond precision before saving to match PostgreSQL precision
    future_date = 1.week.from_now.round(6)
    assert @item.set_deferred!(future_date)
    assert @item.deferred?
    assert_not_nil @item.deferred_at
    assert_equal future_date, @item.deferred_to
  end

  test "items can be returned to todo state" do
    @item.set_done!
    assert @item.done?

    assert @item.mark_todo!
    assert @item.todo?
    assert_nil @item.done_at
  end
end
