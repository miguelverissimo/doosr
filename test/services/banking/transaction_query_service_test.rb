require "test_helper"

class Banking::TransactionQueryServiceTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "queryservice_test@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true,
      roles: User::DEFAULT_ROLES + %w[banking]
    )

    @account = @user.bank_accounts.create!(name: "Checking", account_type: "checking")
    @category = @user.categories.create!(name: "Food", color: "#FF0000")

    @txn1 = @user.bank_transactions.create!(
      date: Date.current,
      description: "Grocery Store",
      value: BigDecimal("-50.00"),
      row_hash: Digest::SHA256.hexdigest("queryservice-txn1"),
      bank_account: @account
    )
    @txn1.set_categories([ @category.id ])

    @txn2 = @user.bank_transactions.create!(
      date: Date.current,
      description: "Salary",
      value: BigDecimal("3000.00"),
      row_hash: Digest::SHA256.hexdigest("queryservice-txn2"),
      bank_account: @account
    )

    @txn3 = @user.bank_transactions.create!(
      date: Date.current - 1.day,
      description: "Transfer to savings",
      value: BigDecimal("-500.00"),
      row_hash: Digest::SHA256.hexdigest("queryservice-txn3"),
      is_transfer: true
    )
  end

  test "call returns Result struct with correct fields" do
    result = Banking::TransactionQueryService.new(@user, { start_date: "all", end_date: "all", transfer_filter: "include" }).call

    assert_respond_to result, :transactions
    assert_respond_to result, :total_count
    assert_respond_to result, :total_income
    assert_respond_to result, :total_expenses
    assert_respond_to result, :net_balance
    assert_respond_to result, :category_breakdown
    assert_respond_to result, :time_series_data
  end

  test "filters by date range" do
    result = Banking::TransactionQueryService.new(@user, {
      start_date: Date.current.to_s,
      end_date: Date.current.to_s,
      transfer_filter: "include"
    }).query

    ids = result.transactions.map(&:id)
    assert_includes ids, @txn1.id
    assert_includes ids, @txn2.id
    assert_not_includes ids, @txn3.id
  end

  test "filters by category_id" do
    result = Banking::TransactionQueryService.new(@user, {
      start_date: "all",
      end_date: "all",
      category_id: @category.id.to_s,
      transfer_filter: "include"
    }).query

    ids = result.transactions.map(&:id)
    assert_includes ids, @txn1.id
    assert_not_includes ids, @txn2.id
  end

  test "filters uncategorized" do
    result = Banking::TransactionQueryService.new(@user, {
      start_date: "all",
      end_date: "all",
      category_id: "uncategorized",
      transfer_filter: "include"
    }).query

    ids = result.transactions.map(&:id)
    assert_not_includes ids, @txn1.id
    assert_includes ids, @txn2.id
  end

  test "filters by search" do
    result = Banking::TransactionQueryService.new(@user, {
      start_date: "all",
      end_date: "all",
      search: "grocery",
      transfer_filter: "include"
    }).query

    assert_equal 1, result.transactions.length
    assert_equal @txn1.id, result.transactions.first.id
  end

  test "filters by bank_account_id" do
    result = Banking::TransactionQueryService.new(@user, {
      start_date: "all",
      end_date: "all",
      bank_account_id: @account.id.to_s,
      transfer_filter: "include"
    }).query

    ids = result.transactions.map(&:id)
    assert_includes ids, @txn1.id
    assert_includes ids, @txn2.id
    assert_not_includes ids, @txn3.id
  end

  test "filters transfers with exclude" do
    result = Banking::TransactionQueryService.new(@user, {
      start_date: "all",
      end_date: "all",
      transfer_filter: "exclude"
    }).query

    ids = result.transactions.map(&:id)
    assert_not_includes ids, @txn3.id
  end

  test "filters transfers with only" do
    result = Banking::TransactionQueryService.new(@user, {
      start_date: "all",
      end_date: "all",
      transfer_filter: "only"
    }).query

    ids = result.transactions.map(&:id)
    assert_includes ids, @txn3.id
    assert_not_includes ids, @txn1.id
  end

  test "filters by min and max amount" do
    result = Banking::TransactionQueryService.new(@user, {
      start_date: "all",
      end_date: "all",
      min_amount: "100",
      transfer_filter: "include"
    }).query

    ids = result.transactions.map(&:id)
    assert_not_includes ids, @txn1.id
    assert_includes ids, @txn2.id
    assert_includes ids, @txn3.id
  end

  test "computes totals excluding transfers" do
    result = Banking::TransactionQueryService.new(@user, {
      start_date: "all",
      end_date: "all",
      transfer_filter: "include"
    }).query

    assert_equal BigDecimal("3000.00"), result.total_income
    assert_equal BigDecimal("50.00"), result.total_expenses
    assert_equal BigDecimal("2950.00"), result.net_balance
  end

  test "query returns lightweight result without analytics" do
    result = Banking::TransactionQueryService.new(@user, {
      start_date: "all",
      end_date: "all",
      transfer_filter: "include"
    }).query

    assert_nil result.category_breakdown
    assert_nil result.time_series_data
    assert_not_nil result.total_count
  end

  test "sorts by date desc by default" do
    result = Banking::TransactionQueryService.new(@user, {
      start_date: "all",
      end_date: "all",
      transfer_filter: "include"
    }).query

    dates = result.transactions.map(&:date)
    assert dates.first >= dates.last
  end

  test "sorts by value" do
    result = Banking::TransactionQueryService.new(@user, {
      start_date: "all",
      end_date: "all",
      sort: "value",
      direction: "asc",
      transfer_filter: "include"
    }).query

    values = result.transactions.map(&:value)
    assert values.first <= values.last
  end
end
