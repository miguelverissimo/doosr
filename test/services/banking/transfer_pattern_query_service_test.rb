require "test_helper"

class Banking::TransferPatternQueryServiceTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "transferquery_test@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true,
      roles: User::DEFAULT_ROLES + %w[banking]
    )

    @pattern1 = @user.transfer_patterns.create!(pattern: "transfer")
    @pattern2 = @user.transfer_patterns.create!(pattern: "transfer to savings")

    @user.bank_transactions.create!(
      date: Date.current,
      description: "Transfer to Savings",
      value: BigDecimal("-500.00"),
      row_hash: Digest::SHA256.hexdigest("transferquery-1"),
      is_transfer: true
    )

    @user.bank_transactions.create!(
      date: Date.current,
      description: "Transfer to Checking",
      value: BigDecimal("-200.00"),
      row_hash: Digest::SHA256.hexdigest("transferquery-2"),
      is_transfer: true
    )

    @user.bank_transactions.create!(
      date: Date.current,
      description: "Grocery Store",
      value: BigDecimal("-30.00"),
      row_hash: Digest::SHA256.hexdigest("transferquery-3"),
      is_transfer: false
    )
  end

  test "returns patterns with matched_transactions_count" do
    service = Banking::TransferPatternQueryService.new(@user)
    patterns = service.call

    assert patterns.all? { |p| p.respond_to?(:matched_transactions_count) }
  end

  test "count reflects actual matching transfer transactions" do
    service = Banking::TransferPatternQueryService.new(@user)
    patterns = service.call

    short_pattern = patterns.find { |p| p.pattern == "transfer" }
    long_pattern = patterns.find { |p| p.pattern == "transfer to savings" }

    assert_equal 2, short_pattern.matched_transactions_count
    assert_equal 1, long_pattern.matched_transactions_count
  end

  test "orders by pattern length descending" do
    service = Banking::TransferPatternQueryService.new(@user)
    patterns = service.call

    assert_equal "transfer to savings", patterns.first.pattern
    assert_equal "transfer", patterns.last.pattern
  end
end
