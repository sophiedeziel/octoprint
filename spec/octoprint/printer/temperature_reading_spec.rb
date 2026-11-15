# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Printer::TemperatureReading do
  describe "modules" do
    subject { described_class.new }

    it { is_expected.to be_a(Octoprint::Deserializable) }
    it { is_expected.to be_a(Octoprint::AutoInitializable) }
  end

  describe ".deserialize" do
    subject(:reading) { described_class.deserialize({ time: 1_395_651_928, actual: 214.8821, target: 220.0 }) }

    its(:time)   { is_expected.to eq 1_395_651_928 }
    its(:actual) { is_expected.to eq 214.8821 }
    its(:target) { is_expected.to eq 220.0 }
    its(:extra)  { is_expected.to be_nil }

    it "collects unknown fields into extra" do
      expect(described_class.deserialize({ actual: 21.3, offset: 0 }).extra).to eq({ offset: 0 })
    end
  end

  describe "#recorded_at" do
    it "returns the timestamp as a Time" do
      expect(described_class.new(time: 1_395_651_928).recorded_at).to eq Time.at(1_395_651_928)
    end

    it "returns nil when the server didn't provide a timestamp" do
      expect(described_class.new(actual: 21.3).recorded_at).to be_nil
    end
  end
end
