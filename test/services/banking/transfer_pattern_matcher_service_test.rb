require "test_helper"

class Banking::TransferPatternMatcherServiceTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "transfermatcher_test@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true,
      roles: User::DEFAULT_ROLES + %w[banking]
    )

    @pattern = @user.transfer_patterns.create!(pattern: "transfer to")

    @matching_txn = @user.bank_transactions.create!(
      date: Date.current,
      description: "Transfer to Savings",
      value: BigDecimal("-500.00"),
      row_hash: Digest::SHA256.hexdigest("transfermatcher-1"),
      is_transfer: false
    )

    @non_matching_txn = @user.bank_transactions.create!(
      date: Date.current,
      description: "Grocery Store",
      value: BigDecimal("-30.00"),
      row_hash: Digest::SHA256.hexdigest("transfermatcher-2"),
      is_transfer: false
    )

    @already_transfer_txn = @user.bank_transactions.create!(
      date: Date.current,
      description: "Transfer to Checking",
      value: BigDecimal("-200.00"),
      row_hash: Digest::SHA256.hexdigest("transfermatcher-3"),
      is_transfer: true
    )
  end

  test "apply_to_existing marks matching non-transfer transactions" do
    service = Banking::TransferPatternMatcherService.new(@user)
    count = service.apply_to_existing(@pattern)

    assert_equal 1, count
    @matching_txn.reload
    assert @matching_txn.is_transfer
    @non_matching_txn.reload
    assert_not @non_matching_txn.is_transfer
  end

  test "rematch marks matching non-transfer transactions" do
    service = Banking::TransferPatternMatcherService.new(@user)
    count = service.rematch(@pattern)

    assert_equal 1, count
    @matching_txn.reload
    assert @matching_txn.is_transfer
  end

  test "unmark_matching unmarks matching transfer transactions" do
    service = Banking::TransferPatternMatcherService.new(@user)
    service.unmark_matching(@pattern)

    @already_transfer_txn.reload
    assert_not @already_transfer_txn.is_transfer
  end

  test "unmark_matching does not affect non-matching transfers" do
    other_transfer = @user.bank_transactions.create!(
      date: Date.current,
      description: "Wire Payment",
      value: BigDecimal("-100.00"),
      row_hash: Digest::SHA256.hexdigest("transfermatcher-4"),
      is_transfer: true
    )

    service = Banking::TransferPatternMatcherService.new(@user)
    service.unmark_matching(@pattern)

    other_transfer.reload
    assert other_transfer.is_transfer
  end

  test "apply_to_existing adds Transfers category to matching transactions" do
    service = Banking::TransferPatternMatcherService.new(@user)
    service.apply_to_existing(@pattern)

    transfers_category = @user.categories.find_by(name: "Transfers")
    assert_not_nil transfers_category
    assert_equal "#109648", transfers_category.color

    @matching_txn.reload
    assert_includes @matching_txn.categories, transfers_category

    @non_matching_txn.reload
    assert_not_includes @non_matching_txn.categories, transfers_category
  end

  test "rematch adds Transfers category to matching transactions" do
    service = Banking::TransferPatternMatcherService.new(@user)
    service.rematch(@pattern)

    transfers_category = @user.categories.find_by(name: "Transfers")
    assert_not_nil transfers_category

    @matching_txn.reload
    assert_includes @matching_txn.categories, transfers_category
  end

  test "unmark_matching removes Transfers category from matching transactions" do
    transfers_category = @user.categories.create!(name: "Transfers", color: "#109648")
    @already_transfer_txn.transaction_categorizations.create!(
      category: transfers_category,
      user: @user
    )

    service = Banking::TransferPatternMatcherService.new(@user)
    service.unmark_matching(@pattern)

    @already_transfer_txn.reload
    assert_not_includes @already_transfer_txn.categories, transfers_category
  end

  test "apply_to_existing does not duplicate Transfers category" do
    transfers_category = @user.categories.create!(name: "Transfers", color: "#109648")
    @matching_txn.transaction_categorizations.create!(
      category: transfers_category,
      user: @user
    )

    service = Banking::TransferPatternMatcherService.new(@user)
    service.apply_to_existing(@pattern)

    @matching_txn.reload
    assert_equal 1, @matching_txn.transaction_categorizations.where(category: transfers_category).count
  end
end
