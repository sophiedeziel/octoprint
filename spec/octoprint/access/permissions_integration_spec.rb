# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Octoprint::Access::Permissions, vcr: { cassette_name: "access/permissions" } do
  describe ".list" do
    it "fetches permissions from the API" do
      permissions = described_class.list

      expect(permissions).to be_an(Array)
      expect(permissions).not_to be_empty
      expect(permissions.first).to be_a(Octoprint::Access::Permission)

      # Check for common permissions
      permission_keys = permissions.map(&:key)
      expect(permission_keys).to include("ADMIN", "SETTINGS", "CONTROL", "MONITOR")

      # Verify structure of a permission
      admin_permission = permissions.find { |p| p.key == "ADMIN" }
      expect(admin_permission).not_to be_nil
      expect(admin_permission.name).to be_a(String)
      expect(admin_permission.dangerous).to be_in([true, false])
      expect(admin_permission.default_groups).to be_an(Array)
      expect(admin_permission.needs).to be_an(Array)
    end
  end
end
