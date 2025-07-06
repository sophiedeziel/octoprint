# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Octoprint::Access::Groups do
  let(:client) { instance_double(Octoprint::Client) }

  before do
    allow(Octoprint).to receive(:client).and_return(client)
  end

  describe ".list" do
    it "fetches and deserializes groups" do
      api_response = [
        {
          key: "admins",
          name: "Administrators",
          description: "Full access",
          permissions: ["ADMIN"],
          subgroups: [],
          needsRole: [],
          default: true,
          removable: false,
          changeable: false,
          toggleable: false
        },
        {
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
      ]

      expect(client).to receive(:request)
        .with("/api/access/groups", { http_method: :get })
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

      operator_group = groups.last
      expect(operator_group.key).to eq("operators")
      expect(operator_group.name).to eq("Operators")
      expect(operator_group.permissions).to eq(%w[CONTROL MONITOR])
      expect(operator_group.subgroups).to eq(["users"])
    end
  end

  describe ".add" do
    it "creates a new group" do
      api_response = {
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
      }

      expect(client).to receive(:request)
        .with("/api/access/groups", {
                http_method: :post,
                params: {
                  key: "testers",
                  name: "Testers",
                  description: "Test group",
                  permissions: ["MONITOR"],
                  subgroups: [],
                  default: false
                }
              })
        .and_return(api_response)

      group = described_class.add(
        key: "testers",
        name: "Testers",
        description: "Test group",
        permissions: ["MONITOR"],
        subgroups: [],
        default: false
      )

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

      expect(client).to receive(:request)
        .with("/api/access/groups/operators", { http_method: :get })
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
      }

      expect(client).to receive(:request)
        .with("/api/access/groups/operators", {
                http_method: :put,
                params: {
                  description: "Updated description",
                  permissions: %w[CONTROL MONITOR FILES_LIST]
                }
              })
        .and_return(api_response)

      group = described_class.update(
        key: "operators",
        params: {
          description: "Updated description",
          permissions: %w[CONTROL MONITOR FILES_LIST]
        }
      )

      expect(group).to be_a(Octoprint::Access::Group)
      expect(group.description).to eq("Updated description")
      expect(group.permissions).to eq(%w[CONTROL MONITOR FILES_LIST])
    end
  end

  describe ".delete" do
    it "deletes a group" do
      expect(client).to receive(:request)
        .with("/api/access/groups/operators", { http_method: :delete })
        .and_return(nil)

      result = described_class.delete(key: "operators")

      expect(result).to be_nil
    end
  end
end
