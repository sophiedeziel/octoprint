# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Octoprint::Access::Permissions do
  include_context "with default Octoprint config"

  let(:client) { Octoprint::Client.new(host: host, api_key: api_key) }

  before do
    allow(Octoprint).to receive(:client).and_return(client)
    # Bypass BaseResource's client method type checking for tests
    allow(described_class).to receive(:client).and_return(client)
  end

  describe ".list" do
    it "fetches and deserializes permissions" do
      api_response = {
        permissions: [
          {
            key: "ADMIN",
            name: "Admin",
            dangerous: true,
            defaultGroups: ["admins"],
            description: "Full administrative access",
            needs: { role: ["admin"] }
          },
          {
            key: "SETTINGS",
            name: "Settings",
            dangerous: false,
            defaultGroups: %w[admins operators],
            description: "Allows access to settings",
            needs: { role: ["settings"] }
          }
        ]
      }

      allow(client).to receive(:request)
        .with("/api/access/permissions", { http_method: :get })
        .and_return(api_response)

      permissions = described_class.list

      expect(permissions).to be_an(Array)
      expect(permissions.length).to eq(2)

      admin_permission = permissions.first
      expect(admin_permission).to be_a(Octoprint::Access::Permission)
      expect(admin_permission.key).to eq("ADMIN")
      expect(admin_permission.name).to eq("Admin")
      expect(admin_permission.dangerous).to be(true)
      expect(admin_permission.default_groups).to eq(["admins"])

      settings_permission = permissions.last
      expect(settings_permission.key).to eq("SETTINGS")
      expect(settings_permission.name).to eq("Settings")
      expect(settings_permission.dangerous).to be(false)
      expect(settings_permission.default_groups).to eq(%w[admins operators])
      expect(settings_permission.needs_role).to eq(["settings"])
    end

    it "handles empty response" do
      allow(client).to receive(:request)
        .with("/api/access/permissions", { http_method: :get })
        .and_return({ permissions: [] })

      permissions = described_class.list

      expect(permissions).to be_an(Array)
      expect(permissions).to be_empty
    end
  end
end
