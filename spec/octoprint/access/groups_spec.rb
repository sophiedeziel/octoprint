# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Octoprint::Access::Groups do
  include_context "with default Octoprint config"

  let(:client) { Octoprint::Client.new(host: host, api_key: api_key) }

  before do
    allow(Octoprint).to receive(:client).and_return(client)
    # Bypass BaseResource's client method type checking for tests
    allow(described_class).to receive(:client).and_return(client)
  end

  describe ".list" do
    it "fetches and deserializes groups" do
      api_response = {
        groups: [
          {
            key: "admins",
            name: "Administrators",
            description: "Full access",
            permissions: ["ADMIN"],
            subgroups: [],
            needs: { group: ["admins"], role: [] },
            default: true,
            removable: false,
            changeable: false,
            toggleable: false,
            dangerous: true
          },
          {
            key: "users",
            name: "Users",
            description: "Can operate the printer",
            permissions: %w[CONTROL MONITOR],
            subgroups: [],
            needs: { group: ["users"], role: [] },
            default: false,
            removable: true,
            changeable: true,
            toggleable: false,
            dangerous: false
          }
        ]
      }

      allow(client).to receive(:request)
        .with("/api/access/groups", http_method: :get)
        .and_return(api_response)

      groups = described_class.list

      expect(groups).to be_an(Array)
      expect(groups.length).to eq(2)

      admin_group = groups.first
      expect(admin_group).to be_a(Octoprint::Access::Group)
      expect(admin_group.key).to eq("admins")
      expect(admin_group.name).to eq("Administrators")
      expect(admin_group.default).to be(true)
      expect(admin_group.removable).to be(false)
      expect(admin_group.dangerous).to be(true)

      user_group = groups.last
      expect(user_group.key).to eq("users")
      expect(user_group.name).to eq("Users")
      expect(user_group.permissions).to eq(%w[CONTROL MONITOR])
      expect(user_group.dangerous).to be(false)
    end
  end

  describe ".add" do
    it "creates a new group" do
      api_response = {
        groups: [{
          key: "testers",
          name: "Testers",
          description: "Test group",
          permissions: ["MONITOR"],
          subgroups: [],
          needsRole: [],
          default: false,
          removable: true,
          changeable: true,
          toggleable: false
        }]
      }

      allow(client).to receive(:request)
        .with("/api/access/groups", {
                http_method: :post,
                body: {
                  key: "testers",
                  name: "Testers",
                  description: "Test group",
                  permissions: ["MONITOR"],
                  subgroups: [],
                  default: false
                },
                headers: {},
                options: {}
              })
        .and_return(api_response)

      group = described_class.add(
        key: "testers",
        name: "Testers",
        description: "Test group",
        permissions: ["MONITOR"],
        subgroups: [],
        default: false
      ).last

      expect(group).to be_a(Octoprint::Access::Group)
      expect(group.key).to eq("testers")
      expect(group.name).to eq("Testers")
      expect(group.description).to eq("Test group")
      expect(group.permissions).to eq(["MONITOR"])
    end
  end

  describe ".get" do
    it "fetches a specific group" do
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
        toggleable: false
      }

      allow(client).to receive(:request)
        .with("/api/access/groups/operators", http_method: :get)
        .and_return(api_response)

      group = described_class.get(key: "operators")

      expect(group).to be_a(Octoprint::Access::Group)
      expect(group.key).to eq("operators")
      expect(group.name).to eq("Operators")
    end
  end

  describe ".update" do
    it "updates a group" do
      api_response = {
        groups: [{
          key: "operators",
          name: "Operators",
          description: "Updated description",
          permissions: %w[CONTROL MONITOR FILES_LIST],
          subgroups: ["users"],
          needsRole: [],
          default: false,
          removable: true,
          changeable: true,
          toggleable: false
        }]
      }

      allow(client).to receive(:request)
        .with("/api/access/groups/operators", {
                http_method: :put,
                body: {
                  description: "Updated description",
                  permissions: %w[CONTROL MONITOR FILES_LIST]
                },
                headers: {},
                options: {}
              })
        .and_return(api_response)

      group = described_class.update(
        key: "operators",
        params: {
          description: "Updated description",
          permissions: %w[CONTROL MONITOR FILES_LIST]
        }
      ).last

      expect(group).to be_a(Octoprint::Access::Group)
      expect(group.description).to eq("Updated description")
      expect(group.permissions).to eq(%w[CONTROL MONITOR FILES_LIST])
    end
  end

  describe ".delete" do
    it "deletes a group" do
      allow(client).to receive(:request)
        .with("/api/access/groups/operators", {
                http_method: :delete,
                body: nil,
                headers: {},
                options: {}
              })
        .and_return(nil)

      result = described_class.delete(key: "operators")

      expect(result).to be_nil
    end

    it "calls super when no key is provided" do
      allow(client).to receive(:request)
        .with("/api/access/groups", {
                http_method: :delete,
                body: nil,
                headers: {},
                options: {}
              })
        .and_return(true)

      result = described_class.delete(path: "/api/access/groups")

      expect(result).to be(true)
    end
  end
end
