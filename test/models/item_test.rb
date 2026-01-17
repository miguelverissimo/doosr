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

  # URL Unfurling tests

  test "has_unfurled_url? returns true when item has unfurled URL" do
    @item.update!(extra_data: { "unfurled_url" => "https://example.com" })
    assert @item.has_unfurled_url?
  end

  test "has_unfurled_url? returns false when item has no unfurled URL" do
    assert_not @item.has_unfurled_url?
  end

  test "has_unfurled_url? returns false when extra_data is empty" do
    @item.update!(extra_data: {})
    assert_not @item.has_unfurled_url?
  end

  test "unfurled_url returns the URL from extra_data" do
    @item.update!(extra_data: { "unfurled_url" => "https://example.com" })
    assert_equal "https://example.com", @item.unfurled_url
  end

  test "unfurled_url returns nil when no URL present" do
    assert_nil @item.unfurled_url
  end

  test "unfurled_title returns the title from extra_data" do
    @item.update!(extra_data: { "unfurled_title" => "Example Domain" })
    assert_equal "Example Domain", @item.unfurled_title
  end

  test "unfurled_title returns nil when no title present" do
    assert_nil @item.unfurled_title
  end

  test "unfurled_description returns the description from extra_data" do
    @item.update!(extra_data: { "unfurled_description" => "This is a test description" })
    assert_equal "This is a test description", @item.unfurled_description
  end

  test "unfurled_description returns nil when no description present" do
    assert_nil @item.unfurled_description
  end

  test "preview_image can be attached" do
    @item.preview_image.attach(
      io: StringIO.new("fake image data"),
      filename: "test.jpg",
      content_type: "image/jpeg"
    )

    assert @item.preview_image.attached?
    assert_equal "test.jpg", @item.preview_image.filename.to_s
  end

  test "deleting item destroys associated notifications" do
    notification = Notification.new(
      user: @user,
      item: @item,
      remind_at: 1.hour.from_now,
      title: "Reminder",
      body: "Test notification"
    )
    notification.save!
    notification_id = notification.id

    assert Notification.exists?(notification_id)

    @item.destroy!

    assert_not Notification.exists?(notification_id)
  end

  test "pending notifications are not sent after item deletion" do
    notification = Notification.new(
      user: @user,
      item: @item,
      remind_at: 1.minute.from_now,
      title: "Reminder",
      status: "pending"
    )
    notification.save!

    @item.destroy!

    assert_not Notification.exists?(notification.id)
  end

  # Reminder indicator tests

  test "has_pending_reminders? returns true when item has pending notifications" do
    notification = Notification.new(
      user: @user,
      item: @item,
      remind_at: 1.hour.from_now,
      title: "Reminder"
    )
    notification.save!

    assert @item.has_pending_reminders?
  end

  test "has_pending_reminders? returns false when item has no notifications" do
    assert_not @item.has_pending_reminders?
  end

  test "has_pending_reminders? returns false when all notifications are sent" do
    notification = Notification.new(
      user: @user,
      item: @item,
      remind_at: 1.hour.from_now,
      title: "Reminder"
    )
    notification.save!
    notification.mark_sent!

    assert_not @item.has_pending_reminders?
  end

  test "next_reminder returns the earliest pending notification" do
    later_notification = Notification.create!(
      user: @user,
      item: @item,
      remind_at: 2.hours.from_now,
      title: "Later reminder"
    )
    earlier_notification = Notification.create!(
      user: @user,
      item: @item,
      remind_at: 1.hour.from_now,
      title: "Earlier reminder"
    )

    assert_equal earlier_notification, @item.next_reminder
  end

  test "next_reminder returns nil when no pending notifications" do
    assert_nil @item.next_reminder
  end

  test "pending_reminders_count returns count of pending notifications" do
    assert_equal 0, @item.pending_reminders_count

    Notification.create!(user: @user, item: @item, remind_at: 1.hour.from_now, title: "First")
    Notification.create!(user: @user, item: @item, remind_at: 2.hours.from_now, title: "Second")

    assert_equal 2, @item.pending_reminders_count
  end

  test "pending_reminders_count excludes sent notifications" do
    pending_notification = Notification.create!(user: @user, item: @item, remind_at: 1.hour.from_now, title: "Pending")
    sent_notification = Notification.create!(user: @user, item: @item, remind_at: 2.hours.from_now, title: "Sent")
    sent_notification.mark_sent!

    assert_equal 1, @item.pending_reminders_count
  end
end
