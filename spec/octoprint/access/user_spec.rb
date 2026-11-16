# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Octoprint::Access::User do
  describe "#initialize" do
    it "creates a user with all attributes" do
      user = described_class.new(
        name: "john_doe",
        active: true,
        admin: false,
        api_key: "ABC123",
        settings: { interface: { color: "dark" } },
        groups: ["operators"],
        permissions: %w[CONTROL MONITOR],
        needs_role: [],
        extra: { foo: "bar" }
      )

      expect(user.name).to eq("john_doe")
      expect(user.active).to be(true)
      expect(user.admin).to be(false)
      expect(user.api_key).to eq("ABC123")
      expect(user.settings).to eq({ interface: { color: "dark" } })
      expect(user.groups).to eq(["operators"])
      expect(user.permissions).to eq(%w[CONTROL MONITOR])
      expect(user.needs_role).to eq([])
      expect(user.extra).to eq({ foo: "bar" })
    end

    it "creates a user with minimal attributes" do
      user = described_class.new(
        name: "jane_doe",
        active: false,
        admin: true,
        settings: {},
        groups: [],
        permissions: [],
        needs_role: [],
        extra: {}
      )

      expect(user.name).to eq("jane_doe")
      expect(user.active).to be(false)
      expect(user.admin).to be(true)
      expect(user.api_key).to be_nil
      expect(user.settings).to eq({})
      expect(user.groups).to eq([])
      expect(user.permissions).to eq([])
      expect(user.needs_role).to eq([])
      expect(user.extra).to eq({})
    end
  end

  describe ".deserialize" do
    it "deserializes a user from API response" do
      api_response = {
        name: "john_doe",
        active: true,
        admin: false,
        apikey: "ABC123",
        settings: { interface: { color: "dark" } },
        groups: ["operators"],
        permissions: %w[CONTROL MONITOR],
        needsRole: [],
        extra_field: "value"
      }

      user = described_class.deserialize(api_response)

      expect(user.name).to eq("john_doe")
      expect(user.active).to be(true)
      expect(user.admin).to be(false)
      expect(user.api_key).to eq("ABC123")
      expect(user.settings).to eq({ interface: { color: "dark" } })
      expect(user.groups).to eq(["operators"])
      expect(user.permissions).to eq(%w[CONTROL MONITOR])
      expect(user.needs_role).to eq([])
      expect(user.extra).to eq({ extra_field: "value" })
    end

    it "handles camelCase to snake_case conversion" do
      api_response = {
        name: "test_user",
        active: true,
        admin: false,
        apikey: "XYZ789",
        settings: {},
        groups: [],
        permissions: [],
        needsRole: ["admin"]
      }

      user = described_class.deserialize(api_response)

      expect(user.api_key).to eq("XYZ789")
      expect(user.needs_role).to eq(["admin"])
    end

    # From spec/cassettes/2_0/access/users_get.yml (role list shortened), after the client's key transform
    it "deserializes an OctoPrint 2.0 user record" do
      user = described_class.deserialize(
        active: true,
        apikey: nil,
        groups: ["users"],
        has_password: true,
        name: "vcruser",
        needs: { group: ["users"], role: %w[connection files_list print] },
        permissions: [],
        settings: {}
      )

      expect(user).to have_attributes(name: "vcruser", active: true, has_password: true, groups: ["users"],
                                      needs_role: %w[connection files_list print], extra: nil)
      expect(user).to have_attributes(admin: nil, user: nil, roles: nil, admin?: false)
    end
  end

  describe "deprecated readers" do
    subject(:user) { described_class.new(admin: true, user: false, roles: %w[admin user]) }

    before { Octoprint::Deprecation.reset! }

    it "returns the 1.x values and warns once per reader" do
      expect do
        expect([user.admin, user.admin, user.user, user.roles]).to eq([true, true, false, %w[admin user]])
      end.to output(
        "[octoprint] Access::User#admin is deprecated: use Access::User#admin?\n" \
        "[octoprint] Access::User#user is deprecated: use Access::User#groups\n" \
        "[octoprint] Access::User#roles is deprecated: use Access::User#needs_role or #groups\n"
      ).to_stderr
    end
  end

  describe "#admin?" do
    it "is true for a member of the admins group" do
      expect(described_class.new(groups: %w[users admins]).admin?).to be(true)
    end

    it "is true with the ADMIN permission (current user)" do
      expect(described_class.new(groups: ["custom"], permissions: %w[STATUS ADMIN]).admin?).to be(true)
    end

    it "is true with the admin role from another group (users list)" do
      expect(described_class.new(groups: ["custom"], permissions: [], needs_role: %w[status admin]).admin?).to be(true)
    end

    it "is false for a regular user" do
      user = described_class.new(groups: ["users"], permissions: ["FILES_LIST"], needs_role: ["files_list"])

      expect(user.admin?).to be(false)
    end

    it "is false without groups, permissions or roles" do
      expect(described_class.new(name: "guest").admin?).to be(false)
    end

    it "ignores the deprecated admin flag" do
      expect(described_class.new(admin: true, groups: ["users"]).admin?).to be(false)
    end
  end
end
