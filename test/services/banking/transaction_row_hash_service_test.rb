require "test_helper"

class Banking::TransactionRowHashServiceTest < ActiveSupport::TestCase
  test "generate returns consistent SHA256 hash" do
    date = Date.new(2026, 1, 15)
    description = "Test Purchase"
    value = BigDecimal("-50.0")

    hash1 = Banking::TransactionRowHashService.generate(date: date, description: description, value: value)
    hash2 = Banking::TransactionRowHashService.generate(date: date, description: description, value: value)

    assert_equal hash1, hash2
    assert_equal 64, hash1.length
  end

  test "generate is case-insensitive on description" do
    date = Date.new(2026, 1, 15)
    value = BigDecimal("-50.0")

    hash1 = Banking::TransactionRowHashService.generate(date: date, description: "Test Purchase", value: value)
    hash2 = Banking::TransactionRowHashService.generate(date: date, description: "test purchase", value: value)

    assert_equal hash1, hash2
  end

  test "generate produces different hashes for different inputs" do
    date = Date.new(2026, 1, 15)
    value = BigDecimal("-50.0")

    hash1 = Banking::TransactionRowHashService.generate(date: date, description: "Purchase A", value: value)
    hash2 = Banking::TransactionRowHashService.generate(date: date, description: "Purchase B", value: value)

    assert_not_equal hash1, hash2
  end

  test "generate_from_transaction matches generate output" do
    user = User.create!(
      email: "rowhash_test@example.com",
      password: "password123",
      password_confirmation: "password123",
      access_confirmed: true,
      roles: User::DEFAULT_ROLES + %w[banking]
    )

    transaction = user.bank_transactions.build(
      date: Date.new(2026, 1, 15),
      description: "Test Purchase",
      value: BigDecimal("-50.0")
    )

    from_txn = Banking::TransactionRowHashService.generate_from_transaction(transaction)
    from_params = Banking::TransactionRowHashService.generate(
      date: transaction.date,
      description: transaction.description,
      value: transaction.value
    )

    assert_equal from_params, from_txn
  end

  test "generate_from_transaction handles nil values gracefully" do
    transaction = Struct.new(:date, :description, :value).new(nil, nil, nil)

    hash = Banking::TransactionRowHashService.generate_from_transaction(transaction)

    assert_equal 64, hash.length
  end
end
