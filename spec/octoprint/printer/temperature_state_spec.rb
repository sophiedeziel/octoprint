# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Printer::TemperatureState do
  describe "modules" do
    subject { described_class.new }

    it { is_expected.to be_a(Octoprint::Deserializable) }
    it { is_expected.to be_a(Octoprint::AutoInitializable) }
  end

  describe ".deserialize" do
    subject(:temperature) { described_class.deserialize(data) }

    let(:data) do
      {
        tool0: { actual: 214.8821, target: 220.0, offset: 0 },
        tool1: { actual: 25.3, target: nil, offset: 0 },
        bed: { actual: 50.221, target: 70.0, offset: 5 },
        chamber: { actual: 30.1, target: 40.0, offset: 0 },
        history: [
          {
            time: 1_395_651_928,
            tool0: { actual: 214.8821, target: 220.0 },
            tool1: { actual: 25.3, target: nil },
            bed: { actual: 50.221, target: 70.0 }
          },
          {
            time: 1_395_651_926,
            tool0: { actual: 212.32, target: 220.0 },
            bed: { actual: 49.1123, target: 70.0 }
          }
        ]
      }
    end

    it "collects the tool entries into tools" do
      expect(temperature.tools.keys).to eq(%i[tool0 tool1])
      expect(temperature.tools.values).to all(be_a(Octoprint::Printer::TemperatureData))
    end

    it "deserializes the bed" do
      expect(temperature.bed).to be_a(Octoprint::Printer::TemperatureData)
      expect(temperature.bed.actual).to eq(50.221)
      expect(temperature.bed.target).to eq(70.0)
      expect(temperature.bed.offset).to eq(5)
    end

    it "deserializes the chamber" do
      expect(temperature.chamber).to be_a(Octoprint::Printer::TemperatureData)
      expect(temperature.chamber.target).to eq(40.0)
    end

    it "deserializes the history" do
      expect(temperature.history).to all(be_a(Octoprint::Printer::TemperatureDataPoint))
      expect(temperature.history.map(&:time)).to eq([1_395_651_928, 1_395_651_926])
      expect(temperature.history.first.tool(1).actual).to eq(25.3)
      expect(temperature.history.last.bed.actual).to eq(49.1123)
    end

    it "has no extra fields" do
      expect(temperature.extra).to be_nil
    end

    context "with only the bed (bed endpoint)" do
      let(:data) { { bed: { actual: 50.221, target: 70.0, offset: 5 } } }

      it "has no tools" do
        expect(temperature.tools).to eq({})
        expect(temperature.tool(0)).to be_nil
      end

      it "has no chamber or history" do
        expect(temperature.chamber).to be_nil
        expect(temperature.history).to be_nil
      end
    end

    context "with an empty history" do
      let(:data) { { tool0: { actual: 20.0, target: 0.0 }, history: [] } }

      it "returns an empty history" do
        expect(temperature.history).to eq([])
      end
    end

    context "with unknown fields" do
      let(:data) { { tool0: { actual: 20.0 }, w: { actual: 21.0 }, tool: { actual: 20.0 } } }

      it "collects them in extra" do
        expect(temperature.extra).to eq({ w: { actual: 21.0 }, tool: { actual: 20.0 } })
        expect(temperature.tools.keys).to eq([:tool0])
      end
    end
  end

  describe "#tool" do
    let(:first_tool) { Octoprint::Printer::TemperatureData.new(actual: 214.8821) }
    let(:second_tool) { Octoprint::Printer::TemperatureData.new(actual: 25.3) }
    let(:temperature) { described_class.new(tools: { tool0: first_tool, tool1: second_tool }) }

    it "returns the tool with the given index" do
      expect(temperature.tool(1)).to be(second_tool)
    end

    it "defaults to the first tool" do
      expect(temperature.tool).to be(first_tool)
    end

    it "returns nil when there is no such tool" do
      expect(temperature.tool(2)).to be_nil
    end

    it "returns nil when tools is nil" do
      expect(described_class.new.tool(0)).to be_nil
    end
  end
end
