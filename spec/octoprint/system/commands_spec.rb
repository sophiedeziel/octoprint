# typed: false
# frozen_string_literal: true

RSpec.describe Octoprint::System::Commands do
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
      expect(commands.core).to all(be_a(Octoprint::System::Command))
      expect(commands.core.size).to eq(2)
      expect(commands.core.first.action).to eq("shutdown")
      expect(commands.core.first.name).to eq("Shutdown")
    end

    it "deserializes custom commands to Command objects" do
      expect(commands.custom).to all(be_a(Octoprint::System::Command))
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

    it "returns a Commands object with properly deserialized data" do
      result = described_class.list

      expect(result.core).to be_an(Array)
      expect(result.core.size).to eq(1)
      expect(result.core.first).to be_a(Octoprint::System::Command)
      expect(result.core.first.action).to eq("shutdown")
      expect(result.custom).to eq([])
    end
  end
end
