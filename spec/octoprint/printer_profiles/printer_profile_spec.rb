# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::PrinterProfiles::PrinterProfile do
  include_context "with default Octoprint config"

  describe "#initialize" do
    let(:profile_data) do
      {
        id: "_default",
        name: "Default",
        color: "default",
        model: "Generic RepRap Printer",
        default: true,
        current: true,
        resource: "http://example.com/api/printerprofiles/_default",
        volume: { width: 200, depth: 200, height: 180 },
        heated_bed: false,
        heated_chamber: false,
        axes: { x: { speed: 6000 }, y: { speed: 6000 }, z: { speed: 200 } },
        extruder: { count: 1 }
      }
    end

    it "initializes with basic attributes" do
      profile = described_class.new(**profile_data)

      expect(profile.id).to eq("_default")
      expect(profile.name).to eq("Default")
      expect(profile.color).to eq("default")
      expect(profile.model).to eq("Generic RepRap Printer")
      expect(profile.default).to be true
      expect(profile.current).to be true
    end

    it "initializes with configuration attributes" do
      profile = described_class.new(**profile_data)

      expect(profile.resource).to eq("http://example.com/api/printerprofiles/_default")
      expect(profile.volume).to eq({ width: 200, depth: 200, height: 180 })
      expect(profile.heated_bed).to be false
      expect(profile.heated_chamber).to be false
      expect(profile.axes).to eq({ x: { speed: 6000 }, y: { speed: 6000 }, z: { speed: 200 } })
      expect(profile.extruder).to eq({ count: 1 })
    end

    it "handles extra attributes via deserialize" do
      extra_data = profile_data.merge(custom_field: "custom_value")
      profile = described_class.deserialize(extra_data)

      expect(profile.extra).to eq({ custom_field: "custom_value" })
    end
  end

  describe ".deserialize" do
    let(:serialized_data) do
      {
        id: "_default",
        name: "Default",
        color: "default",
        model: "Generic RepRap Printer",
        default: true,
        current: true,
        resource: "http://example.com/api/printerprofiles/_default",
        volume: { width: 200, depth: 200, height: 180 },
        heated_bed: false,
        heated_chamber: false,
        axes: { x: { speed: 6000 }, y: { speed: 6000 }, z: { speed: 200 } },
        extruder: { count: 1 }
      }
    end

    it "deserializes from hash with symbol keys" do
      profile = described_class.deserialize(serialized_data)

      expect(profile).to be_a(described_class)
      expect(profile.id).to eq("_default")
      expect(profile.name).to eq("Default")
      expect(profile.model).to eq("Generic RepRap Printer")
      expect(profile.default).to be true
      expect(profile.current).to be true
    end

    it "handles complex nested structures" do
      profile = described_class.deserialize(serialized_data)

      expect(profile.volume).to eq({ width: 200, depth: 200, height: 180 })
      expect(profile.axes).to eq({ x: { speed: 6000 }, y: { speed: 6000 }, z: { speed: 200 } })
      expect(profile.extruder).to eq({ count: 1 })
    end
  end

  describe "inheritance and mixins" do
    it "includes Deserializable" do
      expect(described_class).to include(Octoprint::Deserializable)
    end

    it "includes AutoInitializable" do
      expect(described_class).to include(Octoprint::AutoInitializable)
    end

    it "responds to deserialize" do
      expect(described_class).to respond_to(:deserialize)
    end
  end
end
