# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Slicing do
  include_context "with default Octoprint config"

  let(:profile_data) do
    {
      key: "vcr_fixture",
      display_name: "VCR Fixture",
      default: true,
      resource: "http://octoprint.local/api/slicing/curalegacy/profiles/vcr_fixture"
    }
  end

  describe "inheritance and configuration" do
    it "inherits from BaseResource" do
      expect(described_class).to be < Octoprint::BaseResource
    end

    it "has correct resource path" do
      expect(described_class.instance_variable_get(:@path)).to eq("/api/slicing")
    end
  end

  describe ".list" do
    let(:response) do
      {
        curalegacy: {
          key: "curalegacy",
          display_name: "CuraEngine Legacy",
          default: true,
          configured: false,
          profiles: { vcr_fixture: profile_data }
        }
      }
    end

    before do
      allow(described_class).to receive(:fetch_resource).and_return(response)
    end

    it "fetches all slicers without options by default" do
      described_class.list

      expect(described_class).to have_received(:fetch_resource).with(deserialize: false, options: {})
    end

    it "fetches only the configured slicers when configured is true" do
      described_class.list(configured: true)

      expect(described_class).to have_received(:fetch_resource).with(deserialize: false, options: { configured: true })
    end

    it "does not send the configured option when configured is false" do
      described_class.list(configured: false)

      expect(described_class).to have_received(:fetch_resource).with(deserialize: false, options: {})
    end

    it "returns the slicers by key" do
      slicers = described_class.list

      expect(slicers.keys).to eq([:curalegacy])
      expect(slicers[:curalegacy]).to be_a(described_class::Slicer)
      expect(slicers[:curalegacy].display_name).to eq("CuraEngine Legacy")
    end

    it "deserializes the slicers' profiles" do
      profile = described_class.list[:curalegacy].profiles[:vcr_fixture]

      expect(profile).to be_a(described_class::Profile)
      expect(profile.key).to eq("vcr_fixture")
    end

    context "when no slicer is installed" do
      let(:response) { {} }

      it "returns an empty hash" do
        expect(described_class.list).to eq({})
      end
    end
  end

  describe ".profiles" do
    let(:response) { { vcr_fixture: profile_data } }

    before do
      allow(described_class).to receive(:fetch_resource).and_return(response)
    end

    it "fetches the slicer's profiles without options by default" do
      described_class.profiles(slicer: "curalegacy")

      expect(described_class).to have_received(:fetch_resource)
        .with("curalegacy/profiles", deserialize: false, options: {})
    end

    it "fetches the profiles of a configured slicer when configured is true" do
      described_class.profiles(slicer: "curalegacy", configured: true)

      expect(described_class).to have_received(:fetch_resource)
        .with("curalegacy/profiles", deserialize: false, options: { configured: true })
    end

    it "returns the profiles by key" do
      profiles = described_class.profiles(slicer: "curalegacy")

      expect(profiles.keys).to eq([:vcr_fixture])
      expect(profiles[:vcr_fixture]).to be_a(described_class::Profile)
      expect(profiles[:vcr_fixture].display_name).to eq("VCR Fixture")
    end

    context "when the slicer has no profiles" do
      let(:response) { {} }

      it "returns an empty hash" do
        expect(described_class.profiles(slicer: "curalegacy")).to eq({})
      end
    end
  end

  describe ".get_profile" do
    let(:response) { profile_data.merge(description: "Profile for tests", data: { layer_height: 0.1 }) }

    before do
      allow(described_class).to receive(:fetch_resource).and_return(response)
    end

    it "fetches the profile" do
      described_class.get_profile(slicer: "curalegacy", key: "vcr_fixture")

      expect(described_class).to have_received(:fetch_resource)
        .with("curalegacy/profiles/vcr_fixture", deserialize: false)
    end

    it "returns the profile with its data" do
      profile = described_class.get_profile(slicer: "curalegacy", key: "vcr_fixture")

      expect(profile).to be_a(described_class::Profile)
      expect(profile.key).to eq("vcr_fixture")
      expect(profile.description).to eq("Profile for tests")
      expect(profile.data).to eq({ layer_height: 0.1 })
    end
  end

  describe "requests sent to the server" do
    let(:client) { Octoprint::Client.new(host: host, api_key: api_key) }
    let(:response) { profile_data }

    before do
      allow(described_class).to receive(:client).and_return(client)
      allow(client).to receive(:request).and_return(response)
    end

    describe ".list" do
      let(:response) { {} }

      it "requests the slicers" do
        described_class.list

        expect(client).to have_received(:request).with("/api/slicing", http_method: :get)
      end

      it "adds the configured query parameter when configured is true" do
        described_class.list(configured: true)

        expect(client).to have_received(:request).with("/api/slicing?configured=true", http_method: :get)
      end
    end

    describe ".profiles" do
      let(:response) { {} }

      it "requests the slicer's profiles" do
        described_class.profiles(slicer: "curalegacy", configured: true)

        expect(client).to have_received(:request)
          .with("/api/slicing/curalegacy/profiles?configured=true", http_method: :get)
      end
    end

    describe ".get_profile" do
      it "requests the profile" do
        described_class.get_profile(slicer: "curalegacy", key: "vcr_fixture")

        expect(client).to have_received(:request)
          .with("/api/slicing/curalegacy/profiles/vcr_fixture", http_method: :get)
      end

      it "URL-encodes the slicer and the profile key" do
        described_class.get_profile(slicer: "my slicer", key: "high quality/v2")

        expect(client).to have_received(:request)
          .with("/api/slicing/my%20slicer/profiles/high%20quality%2Fv2", http_method: :get)
      end
    end

    describe ".add_profile" do
      let(:response) { profile_data.merge(key: "draft", display_name: "Draft", default: false) }

      it "sends a PUT request with all the attributes" do
        described_class.add_profile(
          slicer: "curalegacy",
          key: "draft",
          display_name: "Draft",
          description: "Fast and ugly",
          data: { layer_height: 0.3 }
        )

        expect(client).to have_received(:request).with(
          "/api/slicing/curalegacy/profiles/draft",
          http_method: :put,
          body: { displayName: "Draft", description: "Fast and ugly", data: { layer_height: 0.3 } },
          headers: {},
          options: {}
        )
      end

      it "omits the nil attributes and sends empty data by default" do
        described_class.add_profile(slicer: "curalegacy", key: "draft")

        expect(client).to have_received(:request).with(
          "/api/slicing/curalegacy/profiles/draft",
          hash_including(http_method: :put, body: { data: {} })
        )
      end

      it "returns the added profile" do
        profile = described_class.add_profile(slicer: "curalegacy", key: "draft", display_name: "Draft")

        expect(profile).to be_a(described_class::Profile)
        expect(profile.key).to eq("draft")
        expect(profile.display_name).to eq("Draft")
        expect(profile.default?).to be(false)
      end
    end

    describe ".update_profile" do
      it "sends a PATCH request with all the given attributes" do
        described_class.update_profile(
          slicer: "curalegacy",
          key: "vcr_fixture",
          display_name: "Renamed",
          description: "New description",
          default: true,
          data: { layer_height: 0.2 }
        )

        expect(client).to have_received(:request).with(
          "/api/slicing/curalegacy/profiles/vcr_fixture",
          http_method: :patch,
          body: {
            displayName: "Renamed",
            description: "New description",
            default: true,
            data: { layer_height: 0.2 }
          },
          headers: {},
          options: {}
        )
      end

      it "only sends the given attributes" do
        described_class.update_profile(slicer: "curalegacy", key: "vcr_fixture", display_name: "Renamed")

        expect(client).to have_received(:request).with(
          "/api/slicing/curalegacy/profiles/vcr_fixture",
          hash_including(http_method: :patch, body: { displayName: "Renamed" })
        )
      end

      it "sends default when it is false" do
        described_class.update_profile(slicer: "curalegacy", key: "vcr_fixture", default: false)

        expect(client).to have_received(:request).with(
          "/api/slicing/curalegacy/profiles/vcr_fixture",
          hash_including(http_method: :patch, body: { default: false })
        )
      end

      it "sends an empty body when no attribute is given" do
        described_class.update_profile(slicer: "curalegacy", key: "vcr_fixture")

        expect(client).to have_received(:request).with(
          "/api/slicing/curalegacy/profiles/vcr_fixture",
          hash_including(http_method: :patch, body: {})
        )
      end

      it "returns the updated profile" do
        profile = described_class.update_profile(slicer: "curalegacy", key: "vcr_fixture", default: true)

        expect(profile).to be_a(described_class::Profile)
        expect(profile.key).to eq("vcr_fixture")
        expect(profile.default?).to be(true)
      end
    end

    describe ".delete_profile" do
      let(:response) { true }

      it "sends a DELETE request without a body" do
        described_class.delete_profile(slicer: "curalegacy", key: "draft")

        expect(client).to have_received(:request).with(
          "/api/slicing/curalegacy/profiles/draft",
          http_method: :delete,
          body: nil,
          headers: {},
          options: {}
        )
      end

      it "returns true" do
        expect(described_class.delete_profile(slicer: "curalegacy", key: "draft")).to be(true)
      end
    end
  end

  describe ".deserialize_profiles" do
    it "returns an empty hash when given nil" do
      expect(described_class.deserialize_profiles(nil)).to eq({})
    end

    it "returns an empty hash when given an empty hash" do
      expect(described_class.deserialize_profiles({})).to eq({})
    end

    it "deserializes each profile and keeps the keys" do
      profiles = described_class.deserialize_profiles(
        vcr_fixture: profile_data,
        draft: { key: "draft", display_name: "Draft", default: false }
      )

      expect(profiles.keys).to eq(%i[vcr_fixture draft])
      expect(profiles.values).to all(be_a(described_class::Profile))
      expect(profiles[:draft].display_name).to eq("Draft")
    end

    it "keys the profiles by their key rather than the underscored hash key" do
      # The client underscores every hash key in the response: "high-quality" arrives as :high_quality
      profiles = described_class.deserialize_profiles(high_quality: { key: "high-quality", display_name: "HQ" })

      expect(profiles.keys).to eq([:"high-quality"])
    end
  end

  describe ".list keys" do
    before do
      allow(described_class).to receive(:fetch_resource)
        .and_return(my_slicer: { key: "my-slicer", display_name: "Mine", profiles: {} })
    end

    it "keys the slicers by their key rather than the underscored hash key" do
      expect(described_class.list.keys).to eq([:"my-slicer"])
    end
  end
end
