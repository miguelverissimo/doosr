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
end
