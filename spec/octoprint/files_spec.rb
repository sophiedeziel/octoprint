# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Files do
  include_context "with default Octoprint config"

  describe "The empty files container" do
    subject { described_class.new(files: [], free: 1000, total: 3000) }

    its(:files) { are_expected.to eq [] }
    its(:free) { is_expected.to eq 1000 }
    its(:total) { is_expected.to eq 3000 }
  end

  describe "Get local file list", vcr: { cassette_name: "files/list_local" } do
    use_octoprint_server

    subject { described_class.list }

    it { is_expected.to be_a described_class }
    its(:files) { are_expected.to be_a Array }
    its(:free) { is_expected.to eq 198_065_270_784 }
    its(:total) { is_expected.to eq 250_685_575_168 }
  end

  describe "Get printer file list", vcr: { cassette_name: "files/list_printer" } do
    use_octoprint_server

    subject { described_class.list location: :sdcard }

    it { is_expected.to be_a described_class }
    its(:files) { are_expected.to be_a Array }
    its(:free) { is_expected.to be_nil }
    its(:total) { is_expected.to be_nil }
  end

  describe "Upload a file", vcr: { cassette_name: "files/upload" } do
    use_octoprint_server

    subject { described_class.upload("spec/files/test_file.gcode", **params) }

    let(:params) { { location: Octoprint::Location::Local } }

    it { is_expected.to be_a Octoprint::Files::OperationResult }
    its(:done) { is_expected.to be true }
    its(:files) { is_expected.to be_a Hash }
    its(:files) { is_expected.to have_key Octoprint::Location::Local }
    its(:files) { is_expected.not_to have_key Octoprint::Location::SDCard }
    its(:effective_print) { is_expected.to be_nil }
    its(:effective_select) { is_expected.to be_nil }

    context "when uploading to SD card", vcr: { cassette_name: "files/upload_to_sd" } do
      let(:params) { { location: Octoprint::Location::SDCard } }

      its(:done) { is_expected.to be false }
      its(:files) { is_expected.to be_a Hash }
      its(:files) { is_expected.to have_key Octoprint::Location::SDCard }
      its(:files) { is_expected.to have_key Octoprint::Location::Local }
      its(:effective_print) { is_expected.to be false }
      its(:effective_select) { is_expected.to be false }
    end

    context "when uploading to unavailable SD card", vcr: { cassette_name: "files/upload_sd_unavailable" } do
      subject(:sd_unavailable) do
        described_class.upload("spec/files/test_file.gcode", location: Octoprint::Location::SDCard)
      end

      it "raises the correct error" do
        expect { sd_unavailable }.to raise_error(
          Octoprint::Exceptions::ConflictError,
          /Can not upload to SD card, printer is either not operational or already busy/
        )
      end
    end

    context "when chosing to select the file", vcr: { cassette_name: "files/upload_select" } do
      let(:params) { { location: Octoprint::Location::Local, options: { select: true } } }

      its(:effective_print) { is_expected.to be false }
      its(:effective_select) { is_expected.to be true }
    end

    context "when chosing to select the file", vcr: { cassette_name: "files/upload_print" } do
      let(:params) { { location: Octoprint::Location::Local, options: { print: true } } }

      its(:effective_print) { is_expected.to be true }
      its(:effective_select) { is_expected.to be false }
    end

    context "when adding metadata", vcr: { cassette_name: "files/upload_metadata" } do
      let(:params) do
        { location: Octoprint::Location::Local, options: { userdata: "{\"test_value\": \"some value\"}" } }
      end

      # this one does not return the passed metadata back, we need to trust that it was set on a sucessful response
      its(:done) { is_expected.to be true }
    end
  end

  describe "Create a folder", vcr: { cassette_name: "files/create_folder" } do
    use_octoprint_server
    subject { described_class.create_folder(**params) }

    let(:params) { { foldername: "test" } }

    it { is_expected.to be_a Octoprint::Files::OperationResult }
    its(:done) { is_expected.to be true }
    its(:effective_print) { is_expected.to be_nil }
    its(:effective_select) { is_expected.to be_nil }

    describe "folder" do
      subject { described_class.create_folder(**params).folder }

      its(:name) { is_expected.to eq "test" }
      its(:origin) { is_expected.to eq "local" }
      its(:path) { is_expected.to eq "test" }
      its("refs.resource") { is_expected.to eq("#{host}/api/files/local/test") }
    end

    context "with a path", vcr: { cassette_name: "files/create_folder_with_path" } do
      subject { described_class.create_folder(**params).folder.refs.resource }

      before { described_class.create_folder(foldername: "test") }

      let(:params) { { foldername: "new_folder", path: "/test" } }

      it { is_expected.to eq("#{host}/api/files/local/test/new_folder") }
    end

    context "with an ivalid path", vcr: { cassette_name: "files/create_folder_with_invalid_path" } do
      subject(:invalid_path) { described_class.create_folder(**params) }

      let(:params) { { foldername: "new_folder", path: "/does_not_exist" } }

      it {
        expect do
          invalid_path
        end.to raise_error(Octoprint::Exceptions::InternalServerError, /No such file or directory/)
      }
    end
  end
end
