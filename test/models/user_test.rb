require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "should be valid" do
    assert @user.valid?
  end

  test "should have empty roles by default" do
    assert_equal [], @user.roles
  end

  test "should have access_confirmed false by default" do
    assert_equal false, @user.access_confirmed
  end

  # Roles tests

  test "should accept valid roles" do
    @user.roles = [ "admin", "accounting" ]
    assert @user.valid?
    assert @user.save
  end

  test "should reject invalid roles" do
    @user.roles = [ "admin", "invalid_role" ]
    assert_not @user.valid?
    assert_includes @user.errors[:roles], "contains invalid roles: invalid_role"
  end

  test "should accept all available roles" do
    @user.roles = User::AVAILABLE_ROLES
    assert @user.valid?
    assert @user.save
  end

  test "should accept empty roles array" do
    @user.roles = []
    assert @user.valid?
    assert @user.save
  end

  # Role helper methods

  test "has_role? returns true for assigned role" do
    @user.roles = [ "admin" ]
    @user.save!
    assert @user.has_role?("admin")
  end

  test "has_role? returns false for unassigned role" do
    @user.roles = [ "admin" ]
    @user.save!
    assert_not @user.has_role?("accounting")
  end

  test "has_role? works with symbol argument" do
    @user.roles = [ "admin" ]
    @user.save!
    assert @user.has_role?(:admin)
  end

  test "add_role adds role to user" do
    @user.roles = []
    @user.save!
    assert @user.add_role("admin")
    assert_includes @user.roles, "admin"
  end

  test "add_role does not duplicate existing role" do
    @user.roles = [ "admin" ]
    @user.save!
    @user.add_role("admin")
    assert_equal 1, @user.roles.count("admin")
  end

  test "add_role works with symbol argument" do
    @user.roles = []
    @user.save!
    assert @user.add_role(:admin)
    assert_includes @user.roles, "admin"
  end

  test "remove_role removes role from user" do
    @user.roles = [ "admin", "accounting" ]
    @user.save!
    assert @user.remove_role("admin")
    assert_not_includes @user.roles, "admin"
    assert_includes @user.roles, "accounting"
  end

  test "remove_role works with symbol argument" do
    @user.roles = [ "admin" ]
    @user.save!
    assert @user.remove_role(:admin)
    assert_not_includes @user.roles, "admin"
  end

  test "remove_role handles non-existent role gracefully" do
    @user.roles = [ "admin" ]
    @user.save!
    assert @user.remove_role("accounting")
    assert_includes @user.roles, "admin"
  end

  # Access confirmation tests

  test "can toggle access_confirmed" do
    assert_equal false, @user.access_confirmed
    @user.update!(access_confirmed: true)
    assert_equal true, @user.access_confirmed
  end
end
