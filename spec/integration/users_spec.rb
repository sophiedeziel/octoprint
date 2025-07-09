# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Octoprint::Access::Users do
  include_context "with default Octoprint config"
  use_octoprint_server
  describe ".list", vcr: { cassette_name: "access/users_list" } do
    it "fetches users from the API" do
      users = described_class.list

      expect(users).to be_an(Array)
      expect(users).not_to be_empty
      expect(users.first).to be_a(Octoprint::Access::User)

      # Verify structure of a user
      user = users.first
      expect(user.name).to be_a(String)
      expect(user.active).to be_in([true, false])
      expect(user.admin).to be_in([true, false])
      expect(user.api_key).to be_a(String).or(be_nil)
      expect(user.settings).to be_a(Hash)
      expect(user.groups).to be_an(Array)
      expect(user.permissions).to be_an(Array)
      expect(user.needs_role).to be_an(Array)
    end
  end

  describe ".get", vcr: { cassette_name: "access/users_get" } do
    it "fetches a specific user" do
      # Get the first user from the list to test with
      users = described_class.list
      username = users.first.name

      user = described_class.get(username: username)

      expect(user).to be_a(Octoprint::Access::User)
      expect(user.name).to eq(username)
      expect(user.active).to be_in([true, false])
      expect(user.admin).to be_in([true, false])
      expect(user.settings).to be_a(Hash)
      expect(user.groups).to be_an(Array)
      expect(user.permissions).to be_an(Array)
      expect(user.needs_role).to be_an(Array)
    end
  end

  describe "CRUD operations", vcr: { cassette_name: "access/users_crud" } do
    let(:test_username) { "test_user" }

    it "creates, updates, and deletes a user" do
      # Create user
      created_user = described_class.add(
        name: test_username,
        password: "test_password_123",
        active: true,
        admin: false,
        groups: ["users"],
        permissions: ["FILES_LIST"]
      ).find { |u| u.name == test_username }

      expect(created_user).to be_a(Octoprint::Access::User)
      expect(created_user.name).to eq(test_username)
      expect(created_user.active).to be(true)
      expect(created_user.admin).to be(false)
      expect(created_user.groups).to include("users")
      expect(created_user.permissions).to include("FILES_LIST")

      # Update user
      updated_user = described_class.update(
        username: test_username,
        params: {
          active: false,
          groups: %w[readonly]
        }
      ).find { |u| u.name == test_username }

      expect(updated_user).to be_a(Octoprint::Access::User)
      expect(updated_user.name).to eq(test_username)
      expect(updated_user.active).to be(false)
      expect(updated_user.groups).to include("readonly")

      # Test settings operations
      current_settings = described_class.get_settings(username: test_username)
      expect(current_settings).to be_a(Hash)

      new_settings = { interface: { color: "dark" } }
      updated_settings = described_class.update_settings(username: test_username, settings: new_settings)
      expect(updated_settings).to be_a(Hash)
      # expect(updated_settings[:interface]).to be_a(Hash)

      # Test API key operations
      api_key = described_class.generate_api_key(username: test_username)
      expect(api_key).to be_a(String)
      expect(api_key).not_to be_empty

      expect { described_class.delete_api_key(username: test_username) }.not_to raise_error

      # Delete user
      expect { described_class.delete(username: test_username) }.not_to raise_error

      # Verify user was deleted
      expect { described_class.get(username: test_username) }.to raise_error(Octoprint::Exceptions::NotFoundError)
    end
  end
end
