# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Octoprint::Access::Groups, type: :integration, vcr: { cassette_name: "access/groups" } do
  include_context "with default Octoprint config"
  use_octoprint_server
  describe ".list" do
    it "fetches groups from the API" do
      groups = described_class.list

      expect(groups).to be_an(Array)
      expect(groups).not_to be_empty
      expect(groups.first).to be_a(Octoprint::Access::Group)

      # Check for common groups
      group_keys = groups.map(&:key)
      expect(group_keys).to include("admins", "users", "guests")

      # Verify structure of a group
      admin_group = groups.find { |g| g.key == "admins" }
      expect(admin_group).not_to be_nil
      expect(admin_group.name).to be_a(String)
      expect(admin_group.description).to be_a(String)
      expect(admin_group.permissions).to be_an(Array)
      expect(admin_group.subgroups).to be_an(Array)
      expect(admin_group.needs_role).to be_an(Array)
      expect(admin_group.default).to be_in([true, false])
      expect(admin_group.removable).to be_in([true, false])
      expect(admin_group.changeable).to be_in([true, false])
      expect(admin_group.toggleable).to be_in([true, false])
    end
  end

  describe ".get" do
    it "fetches a specific group" do
      group = described_class.get(key: "admins")

      expect(group).to be_a(Octoprint::Access::Group)
      expect(group.key).to eq("admins")
      expect(group.name).to be_a(String)
      expect(group.description).to be_a(String)
      expect(group.permissions).to be_an(Array)
      expect(group.subgroups).to be_an(Array)
      expect(group.needs_role).to be_an(Array)
      expect(group.default).to be_in([true, false])
      expect(group.removable).to be_in([true, false])
      expect(group.changeable).to be_in([true, false])
      expect(group.toggleable).to be_in([true, false])
    end
  end

  describe "CRUD operations" do
    let(:test_group_key) { "test_group" }

    it "creates, updates, and deletes a group", vcr: { cassette_name: "access/groups_crud" } do
      # Create group
      created_group = described_class.add(
        key: test_group_key,
        name: "Test Group",
        description: "A test group for integration testing",
        permissions: ["STATUS"],
        subgroups: [],
        default: false
      ).find { |g| g.name == "Test Group" }

      expect(created_group).to be_a(Octoprint::Access::Group)
      expect(created_group.key).to eq(test_group_key)
      expect(created_group.name).to eq("Test Group")
      expect(created_group.description).to eq("A test group for integration testing")
      expect(created_group.permissions).to eq(["STATUS"])

      # Update group
      updated_group = described_class.update(
        key: test_group_key,
        params: {
          description: "Updated test group description",
          permissions: %w[FILES_LIST]
        }
      ).find { |g| g.key == test_group_key }

      expect(updated_group).to be_a(Octoprint::Access::Group)
      expect(updated_group.description).to eq("Updated test group description")
      expect(updated_group.permissions).to include("FILES_LIST")

      # Delete group
      expect { described_class.delete(key: test_group_key) }.not_to raise_error

      # Verify group was deleted
      expect { described_class.get(key: test_group_key) }.to raise_error(Octoprint::Exceptions::NotFoundError)
    end
  end
end
