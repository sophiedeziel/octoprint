# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Octoprint::Resources::Access::User do
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
  end
end
