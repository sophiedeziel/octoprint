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

  describe "Get file list", vcr: { cassette_name: "files/list_local" } do
    use_octoprint_server

    subject { described_class.list(options: params) }

    let(:params) { {} }

    it { is_expected.to be_a described_class }
    its(:files) { are_expected.to be_a Array }
    its(:files) { are_expected.not_to be_empty }
    its(:files) { are_expected.to all(be_a Octoprint::Files::File) }
    its(:free) { is_expected.not_to be_nil }
    its(:total) { is_expected.not_to be_nil }

    context "when forcing a refresh", vcr: { cassette_name: "files/list_local_refresh" } do
      let(:params) { { force: true } }

      its(:files) { are_expected.to all(be_a Octoprint::Files::File) }
    end

    context "when fetching recursively", vcr: { cassette_name: "files/list_local_recursive" } do
      let(:params) { { recursive: true } }

      its(:files) { are_expected.to all(be_a Octoprint::Files::File) }
    end

    context "when requesting an unsupported option", vcr: { cassette_name: "files/list_local_unsupported_option" } do
      let(:params) { { unsupported: true } }

      # Octoprint just ignores the unsupported option
      its(:files) { are_expected.to all(be_a Octoprint::Files::File) }
    end

    context "when specifying the SD card", vcr: { cassette_name: "files/list_printer" } do
      let(:params) { { location: Octoprint::Location::SDCard } }

      its(:files) { are_expected.to all(be_a Octoprint::Files::File) }
      its(:free) { is_expected.not_to be_nil }
      its(:total) { is_expected.not_to be_nil }
    end
  end

  describe "Retrieve a specific file’s or folder’s information", vcr: { cassette_name: "files/get" } do
    use_octoprint_server
    subject(:get) { described_class.get(**params) }

    let(:params) { { location: Octoprint::Location::Local, filename: "test_file.gcode" } }

    it { is_expected.to be_a Octoprint::Files::File }
    its(:name) { is_expected.to eq "test_file.gcode" }
    its(:origin) { is_expected.to eq Octoprint::Location::Local }
    its(:path) { is_expected.to eq "test_file.gcode" }
    its(:refs) { is_expected.to be_a Octoprint::Files::Refs }
    its("refs.resource") { is_expected.to eq("#{host}/api/files/local/test_file.gcode") }
    its("refs.download") { is_expected.to eq("#{host}/downloads/files/local/test_file.gcode") }
    its("refs.model") { is_expected.to be_nil }
    its(:display_layer_progress) { is_expected.to be_a Hash }
    its(:dashboard) { is_expected.to be_a Hash }
    its(:date) { is_expected.to eq 1_688_948_269 }
    its(:gcode_analysis) { is_expected.to be_a Hash }
    its(:md5_hash) { is_expected.to eq "89e36832ddc7fa8a71c0133b4048343586d31ea2" }
    its(:size) { is_expected.to eq 1164 }
    its(:userdata) { is_expected.to eq({ test_value: "some value" }) }
    its(:children) { is_expected.to be_nil }
    its(:prints) { is_expected.to be_nil }
    its(:statistics) { is_expected.to be_nil }

    context "when location is the SD card", vcr: { cassette_name: "files/get_sd" } do
      let(:params) { { location: Octoprint::Location::SDCard, filename: "TEST_~25.GCO" } }

      it { is_expected.to be_a Octoprint::Files::File }
      its(:name) { is_expected.to eq params[:filename] }
      its(:origin) { is_expected.to eq Octoprint::Location::SDCard }
    end

    context "when the file does not exist", vcr: { cassette_name: "files/get_not_found" } do
      let(:params) { { location: Octoprint::Location::Local, filename: "does_not_exist.gcode" } }

      it {
        expect do
          get
        end.to raise_error(Octoprint::Exceptions::NotFoundError, /The requested URL was not found on the server/)
      }
    end

    context "when the filename is a folder", vcr: { cassette_name: "files/get_folder" } do
      let(:params) { { location: Octoprint::Location::Local, filename: "parent" } }

      its("children.first.name") { is_expected.to eq "child" }
      its("children.first.children") { is_expected.to be_empty }
    end

    context "when the filename is a folder and set recursive", vcr: { cassette_name: "files/get_folder_recursive" } do
      let(:params) { { location: Octoprint::Location::Local, filename: "parent", options: { recursive: true } } }

      its("children.first.name") { is_expected.to eq "child" }
      its("children.first.children") { is_expected.not_to be_empty }
    end
  end

  describe "Upload a file", vcr: { cassette_name: "files/upload" } do
    use_octoprint_server

    subject(:upload) { described_class.upload(file_to_upload, **params) }

    let(:params) { { location: Octoprint::Location::Local } }
    let(:file_to_upload) { "spec/files/test_file.gcode" }

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

    context "when uploading to a folder", vcr: { cassette_name: "files/upload_to_folder" } do
      let(:params) { { location: Octoprint::Location::Local, options: { path: "test_folder" } } }

      its(:done) { is_expected.to be true }
      its(:files) { is_expected.to be_a Hash }
      its(:files) { is_expected.not_to have_key Octoprint::Location::SDCard }
      its(:files) { is_expected.to have_key Octoprint::Location::Local }
      its(:effective_print) { is_expected.to be false }
      its(:effective_select) { is_expected.to be false }
    end

    context "when uploading to unavailable SD card", vcr: { cassette_name: "files/upload_sd_unavailable" } do
      let(:params) { { location: Octoprint::Location::SDCard } }

      it "raises the correct error" do
        expect { upload }.to raise_error(
          Octoprint::Exceptions::ConflictError,
          /Can not upload to SD card, printer is either not operational or already busy/
        )
      end
    end

    context "when uploading to usupported SD card", vcr: { cassette_name: "files/upload_sd_usupported" } do
      let(:params) { { location: Octoprint::Location::SDCard } }

      it "raises the correct error" do
        expect { upload }.to raise_error(
          Octoprint::Exceptions::NotFoundError,
          /The requested URL was not found on the server/
        )
      end
    end

    context "when passing an invalid location", vcr: { cassette_name: "files/upload_sd_usupported" } do
      let(:params) { { location: "invalid" } }

      it "raises the correct error" do
        expect { upload }.to raise_error(
          TypeError,
          /Parameter 'location': Expected type Octoprint::Location, got type/
        )
      end
    end

    context "when uploading an unsupported file", vcr: { cassette_name: "files/upload_unsupported_type" } do
      let(:file_to_upload) { "spec/files/empty.txt" }

      it "raises the correct error" do
        expect { upload }.to raise_error(
          Octoprint::Exceptions::UnsupportedMediaTypeError,
          /Could not upload file, invalid type/
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
      let(:metadata) { { test_value: "some value" } }
      let(:params) do
        { location: Octoprint::Location::Local, options: { userdata: metadata.to_json } }
      end

      # this one does not return the passed metadata back, we need to trust that it was set on a sucessful response
      its(:done) { is_expected.to be true }
      its("files.first.last.userdata") { is_expected.to be_nil }

      it "sets the metadata" do
        upload
        file = described_class.get(location: Octoprint::Location::Local, filename: "test_file.gcode")
        expect(file.userdata).to eq(metadata)
      end
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
