# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Printer::TemperatureData do
  describe "modules" do
    subject { described_class.new }

    it { is_expected.to be_a(Octoprint::Deserializable) }
    it { is_expected.to be_a(Octoprint::AutoInitializable) }
  end

  describe "#initialize" do
    it "initializes with all attributes" do
      data = described_class.new(actual: 214.8821, target: 220.0, offset: 5)

      expect(data.actual).to eq(214.8821)
      expect(data.target).to eq(220.0)
      expect(data.offset).to eq(5)
      expect(data.extra).to be_nil
    end

    it "defaults every attribute to nil" do
      data = described_class.new

      expect(data.actual).to be_nil
      expect(data.target).to be_nil
      expect(data.offset).to be_nil
    end
  end

  describe ".deserialize" do
    it "deserializes the temperatures" do
      data = described_class.deserialize({ actual: 50.221, target: 70.0, offset: 5 })

      expect(data.actual).to eq(50.221)
      expect(data.target).to eq(70.0)
      expect(data.offset).to eq(5)
    end

    it "keeps a nil target" do
      data = described_class.deserialize({ actual: 25.3, target: nil })

      expect(data.target).to be_nil
    end

    it "has no offset in historic data" do
      expect(described_class.deserialize({ actual: 50.221, target: 70.0 }).offset).to be_nil
    end

    it "collects unknown fields in extra" do
      data = described_class.deserialize({ actual: 50.0, target: 70.0, power: 0.5 })

      expect(data.extra).to eq({ power: 0.5 })
    end
  end

  describe "TOOL_KEY" do
    subject(:tool_key) { described_class::TOOL_KEY }

    it "matches tool keys" do
      expect(%w[tool0 tool1 tool12].map { |key| tool_key.match?(key) }).to all(be(true))
    end

    it "does not match other keys" do
      expect(%w[tool bed chamber tool0x xtool0 toolA].map { |key| tool_key.match?(key) }).to all(be(false))
    end
  end

  describe ".extract_tools" do
    it "moves tool entries into a tools hash of temperature data" do
      data = {
        tool0: { actual: 214.8821, target: 220.0 },
        tool1: { actual: 25.3, target: nil },
        bed: { actual: 50.221, target: 70.0 }
      }

      result = described_class.extract_tools(data)

      expect(result).to be(data)
      expect(result.keys).to contain_exactly(:bed, :tools)
      expect(result[:tools].keys).to eq(%i[tool0 tool1])
      expect(result[:tools].values).to all(be_a(described_class))
      expect(result[:tools][:tool0].actual).to eq(214.8821)
    end

    it "leaves the other entries untouched" do
      bed = { actual: 50.221, target: 70.0 }

      result = described_class.extract_tools({ bed: bed, time: 1_395_651_928 })

      expect(result[:bed]).to be(bed)
      expect(result[:time]).to eq(1_395_651_928)
    end

    it "sets an empty tools hash when there are no tools" do
      expect(described_class.extract_tools({ bed: { actual: 50.0 } })[:tools]).to eq({})
    end
  end
end
