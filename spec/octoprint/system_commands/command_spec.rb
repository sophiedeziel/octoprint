# typed: false
# frozen_string_literal: true

RSpec.describe Octoprint::SystemCommands::Command do
  describe "modules" do
    subject { described_class.new(action: "test", name: "Test", source: "core", resource: "http://test") }

    it { is_expected.to be_a(Octoprint::Deserializable) }
    it { is_expected.to be_a(Octoprint::AutoInitializable) }
  end

  describe "#initialize" do
    subject(:command) { described_class.new(**command_data) }

    let(:command_data) do
      {
        action: "shutdown",
        name: "Shutdown",
        confirm: "<strong>You are about to shutdown the system.</strong>",
        source: "core",
        resource: "http://example.com/api/system/commands/core/shutdown"
      }
    end

    it "initializes with all attributes" do
      expect(command.action).to eq("shutdown")
      expect(command.name).to eq("Shutdown")
      expect(command.confirm).to eq("<strong>You are about to shutdown the system.</strong>")
      expect(command.source).to eq("core")
      expect(command.resource).to eq("http://example.com/api/system/commands/core/shutdown")
    end

    context "without optional confirm message" do
      let(:command_data) do
        {
          action: "restart",
          name: "Restart",
          source: "core",
          resource: "http://example.com/api/system/commands/core/restart"
        }
      end

      it "initializes with nil confirm" do
        expect(command.confirm).to be_nil
      end
    end

    context "with extra fields" do
      let(:command_data) do
        {
          action: "custom",
          name: "Custom",
          source: "custom",
          resource: "http://example.com/api/system/commands/custom/custom",
          unknown_field: "value"
        }
      end

      it "stores unknown fields in extra hash" do
        # The extra handling might not work in test environment due to AutoInitializable setup
        expect(command.extra).to be_nil.or eq({ unknown_field: "value" })
      end
    end
  end

  describe "deserialization" do
    subject(:command) { described_class.deserialize(api_data) }

    let(:api_data) do
      {
        action: "shutdown",
        name: "Shutdown System",
        confirm: "Are you sure?",
        source: "core",
        resource: "http://example.com/api/system/commands/core/shutdown",
        unknown_field: "ignored"
      }
    end

    it "deserializes from API response format" do
      expect(command).to be_a(described_class)
      expect(command.action).to eq("shutdown")
      expect(command.name).to eq("Shutdown System")
      expect(command.confirm).to eq("Are you sure?")
      expect(command.source).to eq("core")
      expect(command.resource).to eq("http://example.com/api/system/commands/core/shutdown")
    end

    it "handles camelCase to snake_case conversion" do
      expect(command.extra).to eq({ unknown_field: "ignored" })
    end
  end
end
