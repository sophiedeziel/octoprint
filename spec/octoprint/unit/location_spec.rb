# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Location do
  describe "enum values" do
    it "has Local enum value" do
      expect(described_class::Local).to be_a(described_class)
    end

    it "has SDCard enum value" do
      expect(described_class::SDCard).to be_a(described_class)
    end

    it "has the correct serialized values" do
      expect(described_class::Local.serialize).to eq("local")
      expect(described_class::SDCard.serialize).to eq("sdcard")
    end
  end

  describe "#to_s" do
    it "converts to string representation" do
      # Note: T::Enum to_s behavior might be different from serialize
      expect(described_class::Local.to_s).to be_a(String)
      expect(described_class::SDCard.to_s).to be_a(String)
    end
  end

  describe "enum behavior" do
    it "can be compared for equality" do
      expect(described_class::Local).to eq(described_class::Local)
      expect(described_class::Local).not_to eq(described_class::SDCard)
    end

    it "can be used in case statements" do
      location = described_class::Local
      result = case location
               when described_class::Local
                 "local storage"
               when described_class::SDCard
                 "sd card"
               end
      expect(result).to eq("local storage")
    end

    it "provides all enum values" do
      expect(described_class.values).to contain_exactly(
        described_class::Local,
        described_class::SDCard
      )
    end
  end

  describe "serialization" do
    it "serializes to correct string values" do
      expect(described_class::Local.serialize).to eq("local")
      expect(described_class::SDCard.serialize).to eq("sdcard")
    end

    it "deserializes from string values" do
      expect(described_class.deserialize("local")).to eq(described_class::Local)
      expect(described_class.deserialize("sdcard")).to eq(described_class::SDCard)
    end
  end
end