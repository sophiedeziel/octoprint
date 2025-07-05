# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::PrinterProfiles, type: :integration do
  include_context "with default Octoprint config"

  describe "List printer profiles", vcr: { cassette_name: "printer_profiles/list" } do
    use_octoprint_server

    subject { described_class.list }

    it { is_expected.to be_a described_class }
    its(:profiles) { are_expected.to be_a Hash }
    its(:profiles) { are_expected.not_to be_empty }

    describe "default profile" do
      subject { described_class.list.profiles["_default"] }

      its(:id) { is_expected.to eq "_default" }
      its(:name) { is_expected.to be_a String }
      its(:model) { is_expected.to be_a String }
      its(:color) { is_expected.to be_a String }
      its(:default) { is_expected.to be_a T::Boolean }
      its(:current) { is_expected.to be_a T::Boolean }
      its(:resource) { is_expected.to include("/api/printerprofiles/_default") }
      its(:volume) { is_expected.to be_a Hash }
      its(:heated_bed) { is_expected.to be_a T::Boolean }
      its(:heated_chamber) { is_expected.to be_a T::Boolean }
      its(:axes) { is_expected.to be_a Hash }
      its(:extruder) { is_expected.to be_a Hash }
    end
  end

  describe "Get a specific printer profile", vcr: { cassette_name: "printer_profiles/get_default" } do
    use_octoprint_server

    subject { described_class.get(identifier: "_default") }

    it { is_expected.to be_a Octoprint::PrinterProfiles::PrinterProfile }
    its(:id) { is_expected.to eq "_default" }
    its(:name) { is_expected.to be_a String }
    its(:model) { is_expected.to be_a String }
    its(:color) { is_expected.to be_a String }
    its(:default) { is_expected.to be_a T::Boolean }
    its(:current) { is_expected.to be_a T::Boolean }
    its(:resource) { is_expected.to include("/api/printerprofiles/_default") }

    describe "volume information" do
      subject { described_class.get(identifier: "_default").volume }

      it { is_expected.to be_a Hash }
      it { is_expected.to have_key("width") }
      it { is_expected.to have_key("depth") }
      it { is_expected.to have_key("height") }
    end

    describe "axes information" do
      subject { described_class.get(identifier: "_default").axes }

      it { is_expected.to be_a Hash }
      it { is_expected.to have_key("x") }
      it { is_expected.to have_key("y") }
      it { is_expected.to have_key("z") }
    end

    describe "extruder information" do
      subject { described_class.get(identifier: "_default").extruder }

      it { is_expected.to be_a Hash }
      it { is_expected.to have_key("count") }
    end
  end

  describe "Create a new printer profile", vcr: { cassette_name: "printer_profiles/create" } do
    use_octoprint_server

    subject(:create_profile) { described_class.create(profile: profile_data) }

    let(:profile_data) do
      {
        id: "new_test_printer",
        name: "Test Printer"
      }
    end

    before do
      # Clean up any existing profile with the same ID
      api_key = ENV.fetch("OCTOPRINT_API_KEY", nil)
      host = ENV.fetch("OCTOPRINT_HOST", nil)
      system("curl", "-s", "-X", "DELETE", "-H", "X-Api-Key: #{api_key}",
             "#{host}/api/printerprofiles/new_test_printer")
      system("curl", "-s", "-X", "DELETE", "-H", "X-Api-Key: #{api_key}",
             "#{host}/api/printerprofiles/new_based_printer")
    end

    after do
      # Clean up created profile
      if create_profile&.id
        api_key = ENV.fetch("OCTOPRINT_API_KEY", nil)
        host = ENV.fetch("OCTOPRINT_HOST", nil)
        system("curl", "-s", "-X", "DELETE", "-H", "X-Api-Key: #{api_key}",
               "#{host}/api/printerprofiles/#{create_profile.id}")
      end
    end

    it { is_expected.to be_a Octoprint::PrinterProfiles::PrinterProfile }
    its(:name) { is_expected.to eq "Test Printer" }
    its(:id) { is_expected.to eq "new_test_printer" }

    context "when based on existing profile" do
      subject(:create_based_profile) do
        described_class.create(profile: { id: "new_based_printer", name: "Based Test Printer" }, based_on: "_default")
      end

      its(:name) { is_expected.to eq "Based Test Printer" }
    end
  end

  describe "Update an existing printer profile", vcr: { cassette_name: "printer_profiles/update" } do
    use_octoprint_server

    subject(:update_profile) do
      described_class.update(identifier: created_profile.id, profile: update_data)
    end

    let(:original_profile_data) do
      {
        id: "update_test",
        name: "Original Test Printer",
        model: "Original Model",
        color: "blue"
      }
    end
    let(:update_data) do
      {
        name: "Updated Test Printer",
        model: "Updated Model"
      }
    end
    let(:created_profile) { described_class.create(profile: original_profile_data) }

    after do
      # Clean up created profile
      described_class.delete_profile(identifier: created_profile.id) if created_profile&.id
    end

    it { is_expected.to be_a Octoprint::PrinterProfiles::PrinterProfile }
    its(:name) { is_expected.to eq "Updated Test Printer" }
    its(:model) { is_expected.to eq "Updated Model" }
    its(:color) { is_expected.to eq "blue" } # Should retain original color
  end

  describe "Delete a printer profile", vcr: { cassette_name: "printer_profiles/delete" } do
    use_octoprint_server

    subject(:delete_profile) { described_class.delete_profile(identifier: created_profile.id) }

    let(:profile_data) do
      {
        id: "delete_test",
        name: "Profile to Delete",
        model: "Delete Model",
        color: "green"
      }
    end
    let(:created_profile) { described_class.create(profile: profile_data) }

    it "deletes the profile successfully" do
      expect { delete_profile }.not_to raise_error
    end

    it "profile no longer exists after deletion" do
      delete_profile

      expect { described_class.get(identifier: created_profile.id) }
        .to raise_error(Octoprint::Exceptions::NotFoundError)
    end
  end

  describe "Error handling" do
    use_octoprint_server

    it "raises NotFoundError for non-existent profile" do
      allow(described_class).to receive(:fetch_resource).and_raise(
        Octoprint::Exceptions::NotFoundError,
        "The requested URL was not found on the server"
      )

      expect { described_class.get(identifier: "non_existent") }
        .to raise_error(Octoprint::Exceptions::NotFoundError)
    end

    it "handles delete of current profile gracefully" do
      # Attempting to delete the current profile should raise a conflict error
      allow(described_class).to receive(:delete).and_raise(
        Octoprint::Exceptions::ConflictError,
        "Cannot delete current profile"
      )

      expect { described_class.delete_profile(identifier: "_default") }
        .to raise_error(Octoprint::Exceptions::ConflictError)
    end
  end
end
