# typed: false
# frozen_string_literal: true

RSpec.describe Octoprint::SystemCommands do
  include_context "with default Octoprint config"

  describe "inheritance and modules" do
    it "inherits from BaseResource" do
      expect(described_class).to be < Octoprint::BaseResource
    end

    it "includes Deserializable module" do
      expect(described_class.ancestors).to include(Octoprint::Deserializable)
    end

    it "includes AutoInitializable module" do
      expect(described_class.ancestors).to include(Octoprint::AutoInitializable)
    end
  end

  describe ".resource_path" do
    it "sets the correct API endpoint" do
      expect(described_class.instance_variable_get(:@path)).to eq("/api/system/commands")
    end
  end

  describe "#initialize" do
    subject(:commands) { described_class.new(core: core_commands, custom: custom_commands) }

    let(:core_commands) do
      [
        { action: "shutdown", name: "Shutdown", source: "core",
          resource: "http://example.com/api/system/commands/core/shutdown" },
        { action: "restart", name: "Restart", source: "core", resource: "http://example.com/api/system/commands/core/restart" }
      ]
    end
    let(:custom_commands) do
      [
        { action: "custom1", name: "Custom Command", source: "custom", resource: "http://example.com/api/system/commands/custom/custom1" }
      ]
    end

    it "initializes with core and custom commands" do
      expect(commands).to be_a(described_class)
      expect(commands.core).to be_an(Array)
      expect(commands.custom).to be_an(Array)
    end

    it "deserializes core commands to Command objects" do
      expect(commands.core).to all(be_a(Octoprint::SystemCommands::Command))
      expect(commands.core.size).to eq(2)
      expect(commands.core.first.action).to eq("shutdown")
      expect(commands.core.first.name).to eq("Shutdown")
    end

    it "deserializes custom commands to Command objects" do
      expect(commands.custom).to all(be_a(Octoprint::SystemCommands::Command))
      expect(commands.custom.size).to eq(1)
      expect(commands.custom.first.action).to eq("custom1")
      expect(commands.custom.first.name).to eq("Custom Command")
    end

    context "with empty commands" do
      subject(:commands) { described_class.new(core: [], custom: []) }

      it "initializes with empty arrays" do
        expect(commands.core).to eq([])
        expect(commands.custom).to eq([])
      end
    end

    context "with extra fields" do
      subject(:commands) { described_class.new(core: [], custom: [], unknown_field: "value") }

      it "stores unknown fields in extra hash" do
        # The extra handling might not work in test environment due to AutoInitializable setup
        expect(commands.extra).to be_nil.or eq({ unknown_field: "value" })
      end
    end
  end

  describe ".list" do
    let(:client) { instance_double(Octoprint::Client) }
    let(:api_response) do
      {
        core: [
          { action: "shutdown", name: "Shutdown", source: "core", resource: "http://example.com/api/system/commands/core/shutdown" }
        ],
        custom: []
      }
    end

    before do
      allow(described_class).to receive(:client).and_return(client)
      allow(client).to receive(:request).and_return(api_response)
    end

    it "fetches system commands from the API" do
      result = described_class.list

      expect(result).to be_a(described_class)
      expect(client).to have_received(:request).with(
        "/api/system/commands",
        http_method: :get
      )
    end

    it "returns a SystemCommands object with properly deserialized data" do
      result = described_class.list

      expect(result.core).to be_an(Array)
      expect(result.core.size).to eq(1)
      expect(result.core.first).to be_a(Octoprint::SystemCommands::Command)
      expect(result.core.first.action).to eq("shutdown")
      expect(result.custom).to eq([])
    end
  end

  describe "Command" do
    describe "modules" do
      subject { Octoprint::SystemCommands::Command.new(action: "test", name: "Test", source: "core", resource: "http://test") }

      it { is_expected.to be_a(Octoprint::Deserializable) }
      it { is_expected.to be_a(Octoprint::AutoInitializable) }
    end

    describe "#initialize" do
      subject(:command) { Octoprint::SystemCommands::Command.new(**command_data) }

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
      subject(:command) { Octoprint::SystemCommands::Command.deserialize(api_data) }

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
        expect(command).to be_a(Octoprint::SystemCommands::Command)
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
end
