# typed: true
# frozen_string_literal: true

# Recorded against OctoPrint 1.11.8 with the CuraEngine Legacy plugin (slicer key "curalegacy",
# not configured: no CuraEngine binary). Before recording, the server must have exactly one
# profile, "vcr_fixture", set as the slicer's default:
#
#   curl -X PUT -H "X-Api-Key: $KEY" -H "Content-Type: application/json" \
#     -d '{"displayName":"VCR Fixture","description":"Profile used by the gem tests",
#          "data":{"layer_height":0.2,"wall_thickness":0.8}}' \
#     $HOST/api/slicing/curalegacy/profiles/vcr_fixture
#   curl -X PATCH -H "X-Api-Key: $KEY" -H "Content-Type: application/json" -d '{"default":true}' \
#     $HOST/api/slicing/curalegacy/profiles/vcr_fixture
#
# The add, update and delete examples share the "vcr_added" profile and must be recorded in order.
RSpec.describe Octoprint::Slicing, type: :integration do
  include_context "with default Octoprint config"

  let(:slicer_key) { "curalegacy" }

  describe "List all slicers and slicing profiles", vcr: { cassette_name: "slicing/list" } do
    use_octoprint_server

    subject(:slicers) { described_class.list }

    it { is_expected.to be_a Hash }
    it { is_expected.to include(:curalegacy) }

    describe "the slicer" do
      subject { slicers[:curalegacy] }

      it { is_expected.to be_a Octoprint::Slicing::Slicer }
      its(:key) { is_expected.to eq "curalegacy" }
      its(:display_name) { is_expected.to eq "CuraEngine Legacy" }
      its(:default?) { is_expected.to be false }
      its(:configured?) { is_expected.to be false }
      its(:same_device) { is_expected.to be true }
      its(:extensions) { is_expected.to eq(source: ["stl"], destination: %w[gco gcode g]) }
      its(:profiles) { is_expected.to match(vcr_fixture: an_instance_of(Octoprint::Slicing::Profile)) }
      its(:extra) { is_expected.to be_nil }
    end

    describe "the slicer's profile" do
      subject { slicers[:curalegacy].profiles[:vcr_fixture] }

      its(:key) { is_expected.to eq "vcr_fixture" }
      its(:display_name) { is_expected.to eq "VCR Fixture" }
      its(:description) { is_expected.to eq "Profile used by the gem tests" }
      its(:default?) { is_expected.to be true }
      its(:resource) { is_expected.to end_with "/api/slicing/curalegacy/profiles/vcr_fixture" }
      its(:data) { is_expected.to be_nil }
    end
  end

  describe "List only configured slicers", vcr: { cassette_name: "slicing/list_configured" } do
    use_octoprint_server

    subject { described_class.list(configured: true) }

    it { is_expected.to eq({}) }
  end

  describe "List slicing profiles of a specific slicer", vcr: { cassette_name: "slicing/profiles" } do
    use_octoprint_server

    subject(:profiles) { described_class.profiles(slicer: slicer_key) }

    it { is_expected.to match(vcr_fixture: an_instance_of(Octoprint::Slicing::Profile)) }

    describe "the profile" do
      subject { profiles[:vcr_fixture] }

      its(:key) { is_expected.to eq "vcr_fixture" }
      its(:display_name) { is_expected.to eq "VCR Fixture" }
      its(:default?) { is_expected.to be true }
      its(:data) { is_expected.to be_nil }
    end

    context "with an unknown slicer", vcr: { cassette_name: "slicing/profiles_unknown_slicer" } do
      it "raises a NotFoundError" do
        expect { described_class.profiles(slicer: "unknown") }.to raise_error(Octoprint::Exceptions::NotFoundError)
      end
    end

    context "when only configured slicers are requested and the slicer isn't configured",
            vcr: { cassette_name: "slicing/profiles_configured" } do
      it "raises a NotFoundError" do
        expect { described_class.profiles(slicer: slicer_key, configured: true) }
          .to raise_error(Octoprint::Exceptions::NotFoundError)
      end
    end
  end

  describe "Retrieve specific profile", vcr: { cassette_name: "slicing/get_profile" } do
    use_octoprint_server

    subject { described_class.get_profile(slicer: slicer_key, key: "vcr_fixture") }

    it { is_expected.to be_a Octoprint::Slicing::Profile }
    its(:key) { is_expected.to eq "vcr_fixture" }
    its(:display_name) { is_expected.to eq "VCR Fixture" }
    its(:description) { is_expected.to eq "Profile used by the gem tests" }
    its(:default?) { is_expected.to be true }
    its(:resource) { is_expected.to end_with "/api/slicing/curalegacy/profiles/vcr_fixture" }
    its(:data) { is_expected.to eq(layer_height: 0.2, wall_thickness: 0.8) }
    its(:extra) { is_expected.to be_nil }

    context "with an unknown profile", vcr: { cassette_name: "slicing/get_profile_not_found" } do
      it "raises a NotFoundError" do
        expect { described_class.get_profile(slicer: slicer_key, key: "unknown") }
          .to raise_error(Octoprint::Exceptions::NotFoundError)
      end
    end
  end

  describe "Add slicing profile", vcr: { cassette_name: "slicing/add_profile" } do
    use_octoprint_server

    subject do
      described_class.add_profile(
        slicer: slicer_key,
        key: "vcr_added",
        display_name: "VCR Added",
        description: "Added by the gem tests",
        data: { layer_height: 0.1, wall_thickness: 1.2 }
      )
    end

    it { is_expected.to be_a Octoprint::Slicing::Profile }
    its(:key) { is_expected.to eq "vcr_added" }
    its(:display_name) { is_expected.to eq "VCR Added" }
    its(:description) { is_expected.to eq "Added by the gem tests" }
    its(:default?) { is_expected.to be false }
    its(:resource) { is_expected.to end_with "/api/slicing/curalegacy/profiles/vcr_added" }
    its(:data) { is_expected.to be_nil }

    context "with an unknown slicer", vcr: { cassette_name: "slicing/add_profile_unknown_slicer" } do
      it "raises a NotFoundError" do
        expect { described_class.add_profile(slicer: "unknown", key: "vcr_added") }
          .to raise_error(Octoprint::Exceptions::NotFoundError)
      end
    end
  end

  describe "Update slicing profile", vcr: { cassette_name: "slicing/update_profile" } do
    use_octoprint_server

    subject(:updated) do
      described_class.update_profile(
        slicer: slicer_key,
        key: "vcr_added",
        display_name: "VCR Updated",
        description: "Updated by the gem tests",
        default: true,
        data: { layer_height: 0.3 }
      )
    end

    it { is_expected.to be_a Octoprint::Slicing::Profile }
    its(:key) { is_expected.to eq "vcr_added" }
    its(:display_name) { is_expected.to eq "VCR Updated" }
    its(:description) { is_expected.to eq "Updated by the gem tests" }
    its(:default?) { is_expected.to be true }

    context "when retrieving the updated profile", vcr: { cassette_name: "slicing/update_profile_data" } do
      it "merges the data into the profile's existing data" do
        updated

        profile = described_class.get_profile(slicer: slicer_key, key: "vcr_added")
        expect(profile.data).to eq(layer_height: 0.3, wall_thickness: 1.2)
      end
    end

    context "with an unknown profile", vcr: { cassette_name: "slicing/update_profile_not_found" } do
      it "raises a NotFoundError" do
        expect { described_class.update_profile(slicer: slicer_key, key: "unknown", display_name: "Nope") }
          .to raise_error(Octoprint::Exceptions::NotFoundError)
      end
    end
  end

  describe "Delete slicing profile", vcr: { cassette_name: "slicing/delete_profile" } do
    use_octoprint_server

    it "deletes the profile" do
      expect(described_class.delete_profile(slicer: slicer_key, key: "vcr_added")).to be true
      expect(described_class.profiles(slicer: slicer_key)).not_to have_key(:vcr_added)
    end

    context "with an unknown slicer", vcr: { cassette_name: "slicing/delete_profile_unknown_slicer" } do
      it "raises a NotFoundError" do
        expect { described_class.delete_profile(slicer: "unknown", key: "vcr_added") }
          .to raise_error(Octoprint::Exceptions::NotFoundError)
      end
    end
  end
end
