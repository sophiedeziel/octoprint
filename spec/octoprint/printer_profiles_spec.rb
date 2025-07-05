# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::PrinterProfiles do
  include_context "with default Octoprint config"

  describe "#initialize" do
    let(:profile_data) do
      {
        "_default" => {
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
      }
    end

    it "creates PrinterProfile objects from profile data via deserialize" do
      # Test that deserialize works correctly (this is how it's used in practice)
      profiles = described_class.deserialize(profiles: profile_data)

      expect(profiles.profiles).to be_a(Hash)
      expect(profiles.profiles.length).to eq(1)
      expect(profiles.profiles["_default"]).to be_a(Octoprint::PrinterProfiles::PrinterProfile)
      expect(profiles.profiles["_default"].name).to eq("Default")
      expect(profiles.profiles["_default"].model).to eq("Generic RepRap Printer")
    end

    it "handles direct initialization with transformed data" do
      # When using new directly, we need to pass already transformed data
      transformed_data = {
        "_default" => Octoprint::PrinterProfiles::PrinterProfile.new(**profile_data["_default"])
      }
      profiles = described_class.new(profiles: transformed_data)

      expect(profiles.profiles).to be_a(Hash)
      expect(profiles.profiles.length).to eq(1)
      expect(profiles.profiles["_default"]).to be_a(Octoprint::PrinterProfiles::PrinterProfile)
    end

    it "handles empty profile data" do
      profiles = described_class.new(profiles: {})

      expect(profiles.profiles).to be_a(Hash)
      expect(profiles.profiles).to be_empty
    end
  end

  describe "inheritance and configuration" do
    it "inherits from BaseResource" do
      expect(described_class).to be < Octoprint::BaseResource
    end

    it "has correct resource path" do
      expect(described_class.instance_variable_get(:@path)).to eq("/api/printerprofiles")
    end
  end

  describe "method signatures and behavior patterns" do
    let(:client) { Octoprint::Client.new(host: "http://test.local", api_key: "test_key") }

    before do
      allow(described_class).to receive(:client).and_return(client)
      allow(client).to receive(:request).and_return({})
    end

    it "constructs correct paths for get" do
      allow(described_class).to receive(:fetch_resource).and_return({})

      described_class.get(identifier: "_default")

      expect(described_class).to have_received(:fetch_resource).with("_default", deserialize: false)
    end

    it "constructs correct paths for update" do
      allow(described_class).to receive(:patch).and_return({})

      described_class.update(identifier: "_default", profile: { name: "Updated" })

      expect(described_class).to have_received(:patch).with(
        path: "/api/printerprofiles/_default",
        params: { profile: { name: "Updated" } }
      )
    end

    it "constructs correct paths for delete" do
      allow(described_class).to receive(:delete).and_call_original
      allow(described_class).to receive(:client).and_return(client)
      allow(client).to receive(:request).and_return(true)

      described_class.delete_profile(identifier: "_default")

      expect(client).to have_received(:request).with(
        "/api/printerprofiles/_default",
        hash_including(http_method: :delete)
      )
    end
  end

  describe "create method behavior" do
    before do
      allow(described_class).to receive(:post).and_return({})
    end

    it "creates profile without basedOn parameter" do
      profile_data = { name: "New Printer", model: "Custom Model" }
      described_class.create(profile: profile_data)

      expect(described_class).to have_received(:post).with(
        params: { profile: profile_data }
      )
    end

    it "creates profile with basedOn parameter" do
      profile_data = { name: "New Printer", model: "Custom Model" }
      described_class.create(profile: profile_data, based_on: "_default")

      expect(described_class).to have_received(:post).with(
        params: { profile: profile_data, basedOn: "_default" }
      )
    end

    it "handles nil based_on parameter explicitly" do
      profile_data = { name: "New Printer", model: "Custom Model" }
      described_class.create(profile: profile_data, based_on: nil)

      expect(described_class).to have_received(:post).with(
        params: { profile: profile_data }
      )
    end
  end
end
