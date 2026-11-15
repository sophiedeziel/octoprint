# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Printer::TemperatureDataPoint do
  describe "modules" do
    subject { described_class.new }

    it { is_expected.to be_a(Octoprint::Deserializable) }
    it { is_expected.to be_a(Octoprint::AutoInitializable) }
  end

  describe ".deserialize" do
    subject(:point) { described_class.deserialize(data) }

    let(:data) do
      {
        time: 1_395_651_928,
        tool0: { actual: 214.8821, target: 220.0 },
        tool1: { actual: 25.3, target: nil },
        bed: { actual: 50.221, target: 70.0 },
        chamber: { actual: 30.1, target: 40.0 }
      }
    end

    it "deserializes the time" do
      expect(point.time).to eq(1_395_651_928)
    end

    it "collects the tool entries into tools" do
      expect(point.tools.keys).to eq(%i[tool0 tool1])
      expect(point.tools.values).to all(be_a(Octoprint::Printer::TemperatureData))
      expect(point.tool(0).actual).to eq(214.8821)
      expect(point.tool(1).target).to be_nil
    end

    it "deserializes the bed and chamber" do
      expect(point.bed).to be_a(Octoprint::Printer::TemperatureData)
      expect(point.bed.actual).to eq(50.221)
      expect(point.chamber).to be_a(Octoprint::Printer::TemperatureData)
      expect(point.chamber.target).to eq(40.0)
    end

    it "has no extra fields" do
      expect(point.extra).to be_nil
    end

    context "without a time (tool, bed and chamber endpoints)" do
      let(:data) { { bed: { actual: 50.221, target: 70.0 } } }

      it "has a nil time" do
        expect(point.time).to be_nil
        expect(point.recorded_at).to be_nil
      end

      it "has no tools" do
        expect(point.tools).to eq({})
        expect(point.tool(0)).to be_nil
      end
    end

    context "with unknown fields" do
      let(:data) { { time: 1_395_651_928, tool0: { actual: 20.0 }, w: { actual: 21.0 } } }

      it "collects them in extra" do
        expect(point.extra).to eq({ w: { actual: 21.0 } })
      end
    end
  end

  describe "#tool" do
    let(:first_tool) { Octoprint::Printer::TemperatureData.new(actual: 214.8821) }
    let(:second_tool) { Octoprint::Printer::TemperatureData.new(actual: 25.3) }
    let(:point) { described_class.new(tools: { tool0: first_tool, tool1: second_tool }) }

    it "returns the tool with the given index" do
      expect(point.tool(1)).to be(second_tool)
    end

    it "defaults to the first tool" do
      expect(point.tool).to be(first_tool)
    end

    it "returns nil when there is no such tool" do
      expect(point.tool(5)).to be_nil
    end

    it "returns nil when tools is nil" do
      expect(described_class.new.tool(0)).to be_nil
    end
  end

  describe "#recorded_at" do
    it "returns the time as a Time" do
      recorded_at = described_class.new(time: 1_395_651_928).recorded_at

      expect(recorded_at).to be_a(Time)
      expect(recorded_at).to eq(Time.at(1_395_651_928))
      expect(recorded_at.to_i).to eq(1_395_651_928)
    end

    it "returns nil without a time" do
      expect(described_class.new.recorded_at).to be_nil
    end
  end
end
