# frozen_string_literal: true

require "test_helper"

class Items::UrlUnfurlerServiceTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "detects URL in item title" do
    item = @user.items.create!(
      title: "https://example.com",
      item_type: :completable,
      state: :todo
    )

    service = ::Items::UrlUnfurlerService.new(item)

    # Private method test - verify URL detection works
    url = service.send(:detect_url)
    assert_equal "https://example.com", url
  end

  test "does not detect non-URL text" do
    item = @user.items.create!(
      title: "Just a regular task",
      item_type: :completable,
      state: :todo
    )

    service = ::Items::UrlUnfurlerService.new(item)
    result = service.call

    assert result[:success]

    # Item should be unchanged
    item.reload
    assert_equal "Just a regular task", item.title
    assert_nil item.extra_data["unfurled_url"]
  end

  test "only detects HTTP/HTTPS URLs" do
    item = @user.items.create!(
      title: "ftp://example.com",
      item_type: :completable,
      state: :todo
    )

    service = ::Items::UrlUnfurlerService.new(item)
    url = service.send(:detect_url)

    assert_nil url, "Should not detect non-HTTP(S) URLs"
  end

  test "handles errors gracefully" do
    item = @user.items.create!(
      title: "https://invalid-domain-that-does-not-exist-12345.com",
      item_type: :completable,
      state: :todo
    )

    service = ::Items::UrlUnfurlerService.new(item)
    result = service.call

    # Should return success even if unfurling fails
    assert result[:success]

    # Item title should be unchanged on error
    item.reload
    assert_equal "https://invalid-domain-that-does-not-exist-12345.com", item.title
  end

  test "preserves existing extra_data keys" do
    item = @user.items.create!(
      title: "Regular task",
      item_type: :section,
      state: :todo,
      extra_data: { "permanent_section" => true }
    )

    service = ::Items::UrlUnfurlerService.new(item)
    service.call

    # Should preserve permanent_section flag even if no URL
    item.reload
    assert_equal true, item.extra_data["permanent_section"]
  end

  test "detects URL with other text" do
    item = @user.items.create!(
      title: "Check out https://github.com for code",
      item_type: :completable,
      state: :todo
    )

    service = ::Items::UrlUnfurlerService.new(item)
    url = service.send(:detect_url)

    assert_equal "https://github.com", url
  end
end
