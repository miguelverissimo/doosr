require "test_helper"

class Banking::CategoryPatternMatcherServiceTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "catmatcher_test@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true,
      roles: User::DEFAULT_ROLES + %w[banking]
    )

    @category = @user.categories.create!(name: "Groceries", color: "#00FF00")
    @category2 = @user.categories.create!(name: "Dining", color: "#FF0000")

    @pattern = @user.category_patterns.create!(pattern: "grocery", category: @category)

    @matching_txn = @user.bank_transactions.create!(
      date: Date.current,
      description: "Grocery Store Purchase",
      value: BigDecimal("-30.00"),
      row_hash: Digest::SHA256.hexdigest("catmatcher-1")
    )

    @non_matching_txn = @user.bank_transactions.create!(
      date: Date.current,
      description: "Gas Station",
      value: BigDecimal("-40.00"),
      row_hash: Digest::SHA256.hexdigest("catmatcher-2")
    )

    @already_categorized_txn = @user.bank_transactions.create!(
      date: Date.current,
      description: "Grocery Express",
      value: BigDecimal("-25.00"),
      row_hash: Digest::SHA256.hexdigest("catmatcher-3")
    )
    @already_categorized_txn.set_categories([ @category2.id ])
  end

  test "apply_to_existing applies to uncategorized matching transactions" do
    service = Banking::CategoryPatternMatcherService.new(@user)
    count = service.apply_to_existing(@pattern)

    assert_equal 1, count
    @matching_txn.reload
    assert_equal @pattern.id, @matching_txn.category_pattern_id
    assert_equal [ @category.id ], @matching_txn.categories.pluck(:id)
  end

  test "apply_to_existing skips already-categorized transactions" do
    service = Banking::CategoryPatternMatcherService.new(@user)
    service.apply_to_existing(@pattern)

    @already_categorized_txn.reload
    assert_nil @already_categorized_txn.category_pattern_id
    assert_equal [ @category2.id ], @already_categorized_txn.categories.pluck(:id)
  end

  test "rematch clears non-matching transactions" do
    # First associate the pattern with a transaction
    @non_matching_txn.update!(category_pattern_id: @pattern.id)
    @non_matching_txn.set_categories([ @category.id ])

    service = Banking::CategoryPatternMatcherService.new(@user)
    result = service.rematch(@pattern)

    assert result[:unmatched] >= 1
    @non_matching_txn.reload
    assert_nil @non_matching_txn.category_pattern_id
  end

  test "rematch updates still-matching transactions" do
    @matching_txn.update!(category_pattern_id: @pattern.id)
    @matching_txn.set_categories([ @category2.id ])

    service = Banking::CategoryPatternMatcherService.new(@user)
    result = service.rematch(@pattern)

    assert result[:updated] >= 1
    @matching_txn.reload
    assert_equal [ @category.id ], @matching_txn.categories.pluck(:id)
  end

  test "rematch applies to newly matching uncategorized transactions" do
    service = Banking::CategoryPatternMatcherService.new(@user)
    result = service.rematch(@pattern)

    assert result[:new_matches] >= 1
    @matching_txn.reload
    assert_equal @pattern.id, @matching_txn.category_pattern_id
  end
end
