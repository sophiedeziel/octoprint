# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Octoprint::Resources::Access::Group do
  describe "#initialize" do
    it "creates a group with all attributes" do
      group = described_class.new(
        key: "operators",
        name: "Operators",
        description: "Can operate the printer",
        permissions: %w[CONTROL MONITOR],
        subgroups: ["users"],
        needs_role: [],
        default: false,
        removable: true,
        changeable: true,
        toggleable: false,
        extra: { foo: "bar" }
      )

      expect(group.key).to eq("operators")
      expect(group.name).to eq("Operators")
      expect(group.description).to eq("Can operate the printer")
      expect(group.permissions).to eq(%w[CONTROL MONITOR])
      expect(group.subgroups).to eq(["users"])
      expect(group.needs_role).to eq([])
      expect(group.default).to be(false)
      expect(group.removable).to be(true)
      expect(group.changeable).to be(true)
      expect(group.toggleable).to be(false)
      expect(group.extra).to eq({ foo: "bar" })
    end

    it "creates a group with minimal attributes" do
      group = described_class.new(
        key: "admins",
        name: "Administrators",
        description: "Full access",
        permissions: [],
        subgroups: [],
        needs_role: [],
        default: true,
        removable: false,
        changeable: false,
        toggleable: false,
        extra: {}
      )

      expect(group.key).to eq("admins")
      expect(group.name).to eq("Administrators")
      expect(group.description).to eq("Full access")
      expect(group.permissions).to eq([])
      expect(group.subgroups).to eq([])
      expect(group.needs_role).to eq([])
      expect(group.default).to be(true)
      expect(group.removable).to be(false)
      expect(group.changeable).to be(false)
      expect(group.toggleable).to be(false)
      expect(group.extra).to eq({})
    end
  end

  describe ".deserialize" do
    it "deserializes a group from API response" do
      api_response = {
        key: "operators",
        name: "Operators",
        description: "Can operate the printer",
        permissions: %w[CONTROL MONITOR],
        subgroups: ["users"],
        needsRole: [],
        default: false,
        removable: true,
        changeable: true,
        toggleable: false,
        extra_field: "value"
      }

      group = described_class.deserialize(api_response)

      expect(group.key).to eq("operators")
      expect(group.name).to eq("Operators")
      expect(group.description).to eq("Can operate the printer")
      expect(group.permissions).to eq(%w[CONTROL MONITOR])
      expect(group.subgroups).to eq(["users"])
      expect(group.needs_role).to eq([])
      expect(group.default).to be(false)
      expect(group.removable).to be(true)
      expect(group.changeable).to be(true)
      expect(group.toggleable).to be(false)
      expect(group.extra).to eq({ extra_field: "value" })
    end

    it "handles camelCase to snake_case conversion" do
      api_response = {
        key: "test",
        name: "Test",
        description: "Test group",
        permissions: [],
        subgroups: [],
        needsRole: ["admin"],
        default: false,
        removable: true,
        changeable: true,
        toggleable: false
      }

      group = described_class.deserialize(api_response)

      expect(group.needs_role).to eq(["admin"])
    end
  end
end
