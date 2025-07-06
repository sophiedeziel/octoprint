# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Octoprint::Resources::Access::Permissions do
  let(:client) { instance_double(Octoprint::Client) }

  before do
    allow(Octoprint).to receive(:client).and_return(client)
  end

  describe ".list" do
    it "fetches and deserializes permissions" do
      api_response = [
        {
          key: "ADMIN",
          name: "Admin",
          dangerous: true,
          defaultGroups: ["admins"],
          description: "Full administrative access",
          needs: []
        },
        {
          key: "SETTINGS",
          name: "Settings",
          dangerous: false,
          defaultGroups: %w[admins operators],
          description: "Allows access to settings",
          needs: ["CONNECTION"]
        }
      ]

      expect(client).to receive(:request)
        .with("/api/access/permissions", { http_method: :get })
        .and_return(api_response)

      permissions = described_class.list

      expect(permissions).to be_an(Array)
      expect(permissions.length).to eq(2)

      admin_permission = permissions.first
      expect(admin_permission).to be_a(Octoprint::Resources::Access::Permission)
      expect(admin_permission.key).to eq("ADMIN")
      expect(admin_permission.name).to eq("Admin")
      expect(admin_permission.dangerous).to be(true)
      expect(admin_permission.default_groups).to eq(["admins"])

      settings_permission = permissions.last
      expect(settings_permission.key).to eq("SETTINGS")
      expect(settings_permission.name).to eq("Settings")
      expect(settings_permission.dangerous).to be(false)
      expect(settings_permission.default_groups).to eq(%w[admins operators])
      expect(settings_permission.needs).to eq(["CONNECTION"])
    end

    it "handles empty response" do
      expect(client).to receive(:request)
        .with("/api/access/permissions", { http_method: :get })
        .and_return([])

      permissions = described_class.list

      expect(permissions).to be_an(Array)
      expect(permissions).to be_empty
    end
  end
end
