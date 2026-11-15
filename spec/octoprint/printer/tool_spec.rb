# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Printer::Tool do
  include_context "with default Octoprint config"

  describe "inheritance and configuration" do
    it "inherits from BaseResource" do
      expect(described_class).to be < Octoprint::BaseResource
    end

    it "has correct resource path" do
      expect(described_class.instance_variable_get(:@path)).to eq("/api/printer/tool")
    end
  end

  describe ".get" do
    let(:response) do
      {
        tool0: { actual: 214.8821, target: 220.0, offset: 0 },
        tool1: { actual: 25.3, target: nil, offset: 0 }
      }
    end

    before do
      allow(described_class).to receive(:fetch_resource).and_return(response)
    end

    it "fetches the raw resource without options by default" do
      described_class.get

      expect(described_class).to have_received(:fetch_resource).with(deserialize: false, options: {})
    end

    it "requests the temperature history" do
      described_class.get(history: true)

      expect(described_class).to have_received(:fetch_resource).with(deserialize: false, options: { history: true })
    end

    it "requests a limited temperature history" do
      described_class.get(history: true, limit: 2)

      expect(described_class).to have_received(:fetch_resource).with(
        deserialize: false,
        options: { history: true, limit: 2 }
      )
    end

    it "drops the limit when the history isn't requested" do
      described_class.get(limit: 2)

      expect(described_class).to have_received(:fetch_resource).with(deserialize: false, options: {})
    end

    it "returns a temperature state" do
      temperature = described_class.get

      expect(temperature).to be_a(Octoprint::Printer::TemperatureState)
      expect(temperature.tools.keys).to eq(%i[tool0 tool1])
      expect(temperature.tool(0).actual).to eq(214.8821)
      expect(temperature.tool(1).target).to be_nil
    end
  end

  describe ".issue_command" do
    before do
      allow(described_class).to receive(:post).and_return(true)
    end

    it "posts with the correct command" do
      described_class.issue_command(command: "select")

      expect(described_class).to have_received(:post).with(params: { command: "select" })
    end

    it "merges options into the params" do
      described_class.issue_command(command: "select", options: { tool: "tool1" })

      expect(described_class).to have_received(:post).with(params: { command: "select", tool: "tool1" })
    end
  end

  describe ".target" do
    before do
      allow(described_class).to receive(:issue_command).and_return(true)
    end

    it "delegates to issue_command with the targets" do
      described_class.target(tool0: 220, tool1: 205)

      expect(described_class).to have_received(:issue_command).with(
        command: "target",
        options: { targets: { tool0: 220, tool1: 205 } }
      )
    end

    it "supports the active tool key" do
      described_class.target(tool: 220)

      expect(described_class).to have_received(:issue_command).with(
        command: "target",
        options: { targets: { tool: 220 } }
      )
    end
  end

  describe ".offset" do
    before do
      allow(described_class).to receive(:issue_command).and_return(true)
    end

    it "delegates to issue_command with the offsets" do
      described_class.offset(tool0: 10, tool1: -5)

      expect(described_class).to have_received(:issue_command).with(
        command: "offset",
        options: { offsets: { tool0: 10, tool1: -5 } }
      )
    end
  end

  describe ".select_tool" do
    before do
      allow(described_class).to receive(:issue_command).and_return(true)
    end

    it "delegates to issue_command with the select command" do
      described_class.select_tool("tool1")

      expect(described_class).to have_received(:issue_command).with(command: "select", options: { tool: "tool1" })
    end

    it "converts a symbol tool to a string" do
      described_class.select_tool(:tool0)

      expect(described_class).to have_received(:issue_command).with(command: "select", options: { tool: "tool0" })
    end
  end

  describe ".extrude" do
    before do
      allow(described_class).to receive(:issue_command).and_return(true)
    end

    it "delegates to issue_command without a speed by default" do
      described_class.extrude(5)

      expect(described_class).to have_received(:issue_command).with(command: "extrude", options: { amount: 5 })
    end

    it "includes the speed when given" do
      described_class.extrude(-3, speed: 300)

      expect(described_class).to have_received(:issue_command).with(
        command: "extrude",
        options: { amount: -3, speed: 300 }
      )
    end
  end

  describe ".flowrate" do
    before do
      allow(described_class).to receive(:issue_command).and_return(true)
    end

    it "delegates to issue_command with the factor" do
      described_class.flowrate(95)

      expect(described_class).to have_received(:issue_command).with(command: "flowrate", options: { factor: 95 })
    end

    it "accepts a float factor" do
      described_class.flowrate(0.95)

      expect(described_class).to have_received(:issue_command).with(command: "flowrate", options: { factor: 0.95 })
    end
  end
end
