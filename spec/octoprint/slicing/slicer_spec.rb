# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Slicing::Slicer do
  it "includes AutoInitializable and Deserializable" do
    slicer = described_class.new(key: "curalegacy", profiles: {})

    expect(slicer).to be_a(Octoprint::AutoInitializable)
    expect(slicer).to be_a(Octoprint::Deserializable)
  end

  describe ".deserialize" do
    subject(:slicer) { described_class.deserialize(data) }

    let(:data) do
      {
        key: "curalegacy",
        display_name: "CuraEngine Legacy",
        default: false,
        configured: false,
        same_device: true,
        extensions: { source: ["stl"], destination: %w[gco gcode g] },
        profiles: {
          vcr_fixture: {
            key: "vcr_fixture",
            display_name: "VCR Fixture",
            default: true,
            resource: "http://x/api/slicing/curalegacy/profiles/vcr_fixture"
          }
        }
      }
    end

    its(:key)          { is_expected.to eq("curalegacy") }
    its(:display_name) { is_expected.to eq("CuraEngine Legacy") }
    its(:default)      { is_expected.to be(false) }
    its(:configured)   { is_expected.to be(false) }
    its(:same_device)  { is_expected.to be(true) }
    its(:extensions)   { is_expected.to eq({ source: ["stl"], destination: %w[gco gcode g] }) }
    its(:extra)        { is_expected.to be_nil }
    its(:default?)     { is_expected.to be(false) }
    its(:configured?)  { is_expected.to be(false) }

    it "deserializes the profiles by key" do
      expect(slicer.profiles.keys).to eq([:vcr_fixture])
      expect(slicer.profiles[:vcr_fixture]).to be_a(Octoprint::Slicing::Profile)
    end

    it "deserializes the profiles' attributes" do
      profile = slicer.profiles[:vcr_fixture]

      expect(profile.key).to eq("vcr_fixture")
      expect(profile.display_name).to eq("VCR Fixture")
      expect(profile.default?).to be(true)
      expect(profile.resource).to eq("http://x/api/slicing/curalegacy/profiles/vcr_fixture")
      expect(profile.data).to be_nil
    end

    context "when the slicer is the default and is configured" do
      let(:data) { { key: "curalegacy", default: true, configured: true, profiles: {} } }

      its(:default?)    { is_expected.to be(true) }
      its(:configured?) { is_expected.to be(true) }
    end

    context "when profiles are missing" do
      let(:data) { { key: "curalegacy" } }

      its(:profiles) { is_expected.to eq({}) }
    end

    context "when profiles are null" do
      let(:data) { { key: "curalegacy", profiles: nil } }

      its(:profiles) { is_expected.to eq({}) }
    end

    context "with unknown fields" do
      let(:data) { { key: "curalegacy", profiles: {}, version: "1.0" } }

      its(:extra) { is_expected.to eq({ version: "1.0" }) }
    end
  end

  describe "#default?" do
    it "is true when default is true" do
      expect(described_class.new(key: "curalegacy", profiles: {}, default: true).default?).to be(true)
    end

    it "is false when default is false" do
      expect(described_class.new(key: "curalegacy", profiles: {}, default: false).default?).to be(false)
    end

    it "is false when default is nil" do
      expect(described_class.new(key: "curalegacy", profiles: {}).default?).to be(false)
    end
  end

  describe "#configured?" do
    it "is true when configured is true" do
      expect(described_class.new(key: "curalegacy", profiles: {}, configured: true).configured?).to be(true)
    end

    it "is false when configured is false" do
      expect(described_class.new(key: "curalegacy", profiles: {}, configured: false).configured?).to be(false)
    end

    it "is false when configured is nil" do
      expect(described_class.new(key: "curalegacy", profiles: {}).configured?).to be(false)
    end
  end
end
