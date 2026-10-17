require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "normalizes email and stores only a password digest" do
    password = "strong-example-password"
    user = User.create!(
      email: "  Worker@Example.com ",
      password: password,
      password_confirmation: password
    )

    assert_equal "worker@example.com", user.email
    assert_not_equal password, user.password_digest
    assert user.authenticate(password)
  end

  test "rejects duplicate email addresses regardless of case" do
    User.create!(
      email: "worker@example.com",
      password: "strong-example-password",
      password_confirmation: "strong-example-password"
    )
    duplicate = User.new(
      email: "WORKER@example.com",
      password: "another-strong-password",
      password_confirmation: "another-strong-password"
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors.attribute_names, :email
  end

  test "requires a long password and its confirmation" do
    user = User.new(email: "worker@example.com", password: "short", password_confirmation: "short")

    assert_not user.valid?
    assert_includes user.errors.attribute_names, :password
  end

  test "rejects passwords that exceed bcrypt's byte limit" do
    password = "é" * 37
    user = User.new(
      email: "worker@example.com",
      password: password,
      password_confirmation: password
    )

    assert_not user.valid?
    assert_includes user.errors.attribute_names, :password
  end
end
