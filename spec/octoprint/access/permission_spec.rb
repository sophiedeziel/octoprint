# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Octoprint::Access::Permission do
  describe "#initialize" do
    it "creates a permission with all attributes" do
      permission = described_class.new(
        key: "SETTINGS",
        name: "Settings",
        dangerous: false,
        default_groups: %w[admins operators],
        description: "Allows access to settings",
        needs: ["CONNECTION"],
        extra: { foo: "bar" }
      )

      expect(permission.key).to eq("SETTINGS")
      expect(permission.name).to eq("Settings")
      expect(permission.dangerous).to be(false)
      expect(permission.default_groups).to eq(%w[admins operators])
      expect(permission.description).to eq("Allows access to settings")
      expect(permission.needs).to eq(["CONNECTION"])
      expect(permission.extra).to eq({ foo: "bar" })
    end

    it "creates a permission with minimal attributes" do
      permission = described_class.new(
        key: "MONITOR",
        name: "Monitor",
        dangerous: false,
        default_groups: [],
        needs: [],
        extra: {}
      )

      expect(permission.key).to eq("MONITOR")
      expect(permission.name).to eq("Monitor")
      expect(permission.dangerous).to be(false)
      expect(permission.default_groups).to eq([])
      expect(permission.description).to be_nil
      expect(permission.needs).to eq([])
      expect(permission.extra).to eq({})
    end
  end

  describe ".deserialize" do
    it "deserializes a permission from API response" do
      api_response = {
        key: "ADMIN",
        name: "Admin",
        dangerous: true,
        defaultGroups: ["admins"],
        description: "Full administrative access",
        needs: [],
        extra_field: "value"
      }

      permission = described_class.deserialize(api_response)

      expect(permission.key).to eq("ADMIN")
      expect(permission.name).to eq("Admin")
      expect(permission.dangerous).to be(true)
      expect(permission.default_groups).to eq(["admins"])
      expect(permission.description).to eq("Full administrative access")
      expect(permission.needs).to eq([])
      expect(permission.extra).to eq({ extra_field: "value" })
    end

    it "handles camelCase to snake_case conversion" do
      api_response = {
        key: "TEST",
        name: "Test",
        dangerous: false,
        defaultGroups: ["test_group"],
        needs: []
      }

      permission = described_class.deserialize(api_response)

      expect(permission.default_groups).to eq(["test_group"])
    end
  end
end
