# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Slicing::Profile do
  it "includes AutoInitializable and Deserializable" do
    profile = described_class.new(key: "vcr_fixture")

    expect(profile).to be_a(Octoprint::AutoInitializable)
    expect(profile).to be_a(Octoprint::Deserializable)
  end

  describe ".deserialize" do
    subject(:profile) { described_class.deserialize(data) }

    context "when the profile comes from a list (without data)" do
      let(:data) do
        {
          key: "vcr_fixture",
          display_name: "VCR Fixture",
          default: true,
          resource: "http://x/api/slicing/curalegacy/profiles/vcr_fixture"
        }
      end

      its(:key)          { is_expected.to eq("vcr_fixture") }
      its(:display_name) { is_expected.to eq("VCR Fixture") }
      its(:description)  { is_expected.to be_nil }
      its(:default)      { is_expected.to be(true) }
      its(:default?)     { is_expected.to be(true) }
      its(:resource)     { is_expected.to eq("http://x/api/slicing/curalegacy/profiles/vcr_fixture") }
      its(:data)         { is_expected.to be_nil }
      its(:extra)        { is_expected.to be_nil }
    end

    context "when the profile is retrieved with its data" do
      let(:data) do
        {
          key: "vcr_fixture",
          display_name: "VCR Fixture",
          description: "Profile for tests",
          default: false,
          resource: "http://x/api/slicing/curalegacy/profiles/vcr_fixture",
          data: { layer_height: 0.1, fill_density: 20, start_gcode: ["G28"] }
        }
      end

      its(:description) { is_expected.to eq("Profile for tests") }
      its(:default?)    { is_expected.to be(false) }
      its(:data)        { is_expected.to eq({ layer_height: 0.1, fill_density: 20, start_gcode: ["G28"] }) }
      its(:extra)       { is_expected.to be_nil }
    end

    context "when the API sends camelCase keys" do
      let(:data) { { key: "vcr_fixture", displayName: "VCR Fixture" } }

      its(:display_name) { is_expected.to eq("VCR Fixture") }
    end

    context "with unknown fields" do
      let(:data) { { key: "vcr_fixture", slicer: "curalegacy" } }

      its(:extra) { is_expected.to eq({ slicer: "curalegacy" }) }
    end
  end

  describe "#default?" do
    it "is true when default is true" do
      expect(described_class.new(key: "vcr_fixture", default: true).default?).to be(true)
    end

    it "is false when default is false" do
      expect(described_class.new(key: "vcr_fixture", default: false).default?).to be(false)
    end

    it "is false when default is nil" do
      expect(described_class.new(key: "vcr_fixture").default?).to be(false)
    end
  end
end
