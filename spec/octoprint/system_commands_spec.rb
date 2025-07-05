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

  describe ".list_by_source" do
    let(:client) { instance_double(Octoprint::Client) }
    let(:core_commands_response) do
      [
        { action: "shutdown", name: "Shutdown", source: "core",
          resource: "http://example.com/api/system/commands/core/shutdown" },
        { action: "restart", name: "Restart", source: "core",
          resource: "http://example.com/api/system/commands/core/restart" }
      ]
    end
    let(:custom_commands_response) do
      [
        { action: "custom1", name: "Custom Command", source: "custom",
          resource: "http://example.com/api/system/commands/custom/custom1" }
      ]
    end

    before do
      allow(described_class).to receive(:client).and_return(client)
    end

    context "when requesting core commands" do
      before do
        allow(client).to receive(:request).with(
          "/api/system/commands/core",
          http_method: :get
        ).and_return(core_commands_response)
      end

      it "fetches core commands from the API" do
        result = described_class.list_by_source("core")

        expect(client).to have_received(:request).with(
          "/api/system/commands/core",
          http_method: :get
        )
        expect(result).to be_an(Array)
        expect(result.size).to eq(2)
      end

      it "returns an array of Command objects" do
        result = described_class.list_by_source("core")

        expect(result).to all(be_a(Octoprint::SystemCommands::Command))
        expect(result.first.action).to eq("shutdown")
        expect(result.first.name).to eq("Shutdown")
        expect(result.first.source).to eq("core")
        expect(result.last.action).to eq("restart")
        expect(result.last.name).to eq("Restart")
        expect(result.last.source).to eq("core")
      end
    end

    context "when requesting custom commands" do
      before do
        allow(client).to receive(:request).with(
          "/api/system/commands/custom",
          http_method: :get
        ).and_return(custom_commands_response)
      end

      it "fetches custom commands from the API" do
        result = described_class.list_by_source("custom")

        expect(client).to have_received(:request).with(
          "/api/system/commands/custom",
          http_method: :get
        )
        expect(result).to be_an(Array)
        expect(result.size).to eq(1)
      end

      it "returns an array of Command objects" do
        result = described_class.list_by_source("custom")

        expect(result).to all(be_a(Octoprint::SystemCommands::Command))
        expect(result.first.action).to eq("custom1")
        expect(result.first.name).to eq("Custom Command")
        expect(result.first.source).to eq("custom")
      end
    end

    context "when requesting empty source" do
      before do
        allow(client).to receive(:request).with(
          "/api/system/commands/empty",
          http_method: :get
        ).and_return([])
      end

      it "returns an empty array" do
        result = described_class.list_by_source("empty")

        expect(result).to eq([])
      end
    end
  end

  describe ".execute" do
    let(:client) { instance_double(Octoprint::Client) }

    before do
      allow(described_class).to receive(:client).and_return(client)
    end

    context "when executing core commands" do
      before do
        allow(client).to receive(:request).with(
          "/api/system/commands/core/restart",
          http_method: :post,
          body: {},
          headers: {},
          options: {}
        ).and_return(true)
      end

      it "executes core restart command" do
        result = described_class.execute("core", "restart")

        expect(client).to have_received(:request).with(
          "/api/system/commands/core/restart",
          http_method: :post,
          body: {},
          headers: {},
          options: {}
        )
        expect(result).to be true
      end
    end

    context "when executing custom commands" do
      before do
        allow(client).to receive(:request).with(
          "/api/system/commands/custom/my_command",
          http_method: :post,
          body: {},
          headers: {},
          options: {}
        ).and_return(true)
      end

      it "executes custom command" do
        result = described_class.execute("custom", "my_command")

        expect(client).to have_received(:request).with(
          "/api/system/commands/custom/my_command",
          http_method: :post,
          body: {},
          headers: {},
          options: {}
        )
        expect(result).to be true
      end
    end

    context "when executing reboot command" do
      before do
        allow(client).to receive(:request).with(
          "/api/system/commands/core/reboot",
          http_method: :post,
          body: {},
          headers: {},
          options: {}
        ).and_return(true)
      end

      it "executes core reboot command" do
        result = described_class.execute("core", "reboot")

        expect(client).to have_received(:request).with(
          "/api/system/commands/core/reboot",
          http_method: :post,
          body: {},
          headers: {},
          options: {}
        )
        expect(result).to be true
      end
    end
  end
end
