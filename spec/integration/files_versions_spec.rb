# typed: false
# frozen_string_literal: true

# The Files API against OctoPrint 1.11 and 2.0: the same models whatever the server version.
# The printer storage specs need a connected printer (virtual printer, port VIRTUAL, 115200 baud) when recording.
RSpec.describe Octoprint::Files, type: :integration do
  include_context "with default Octoprint config"

  let(:local) { Octoprint::Location::Local }
  let(:printer) { Octoprint::Location::Printer }
  let(:gcode) { "spec/files/test_file.gcode" }

  on_octoprint_versions do |version|
    describe ".list", vcr: { cassette_name: "files/storage_local" } do
      use_octoprint_server
      subject(:storage) { described_class.list }

      before { described_class.upload(gcode) }
      after { described_class.delete_file(filename: "test_file.gcode") }

      it { is_expected.to be_a described_class }
      its(:key) { is_expected.to eq "local" }
      its(:usage) { is_expected.to be_a Octoprint::Files::Usage }
      its("usage.free") { is_expected.to be_a Integer }
      its("usage.total") { is_expected.to be_a Integer }
      its(:free) { is_expected.to eq storage.usage.free }
      its(:total) { is_expected.to eq storage.usage.total }
      its("files.first.name") { is_expected.to eq "test_file.gcode" }
      its("files.first.origin") { is_expected.to eq Octoprint::Location::Local }
      its(:name) { is_expected.to eq({ "1.11" => nil, "2.0" => "Local" }.fetch(version)) }

      it "has the storage capabilities on 2.0 only" do
        if version == "2.0"
          expect(storage.capabilities).to include(add_folder: true, thumbnails: true, copy_file: true)
        else
          expect(storage.capabilities).to be_nil
        end
      end
    end

    describe ".list_all", vcr: { cassette_name: "files/list_all" } do
      use_octoprint_server
      subject(:storages) { described_class.list_all }

      before { described_class.upload(gcode) }
      after { described_class.delete_file(filename: "test_file.gcode") }

      it { is_expected.to be_a Hash }
      it { is_expected.to include(:local) }
      it { expect(storages.values).to all(be_a described_class) }
      it { expect(storages[:local].key).to eq "local" }
      it { expect(storages[:local].files.map(&:name)).to include "test_file.gcode" }
      it { expect(storages[:local].usage.total).to be_a Integer }
    end

    describe ".upload", vcr: { cassette_name: "files/upload_file" } do
      use_octoprint_server
      subject(:result) { described_class.upload(gcode) }

      after { described_class.delete_file(filename: "test_file.gcode") }

      it { is_expected.to be_a Octoprint::Files::OperationResult }
      its(:done) { is_expected.to be true }
      its(:file) { is_expected.to be_a Octoprint::Files::File }
      its("file.name") { is_expected.to eq "test_file.gcode" }
      its("file.origin") { is_expected.to eq Octoprint::Location::Local }
      its("file.refs.resource") { is_expected.to eq "#{host}/api/files/local/test_file.gcode" }
      its(:folder) { is_expected.to be_nil }
    end

    describe ".copy within a storage", vcr: { cassette_name: "files/copy_same_storage" } do
      use_octoprint_server
      subject(:copy) do
        described_class.copy(filename: "test_file.gcode", destination: "copied.gcode", storage: local)
      end

      before { described_class.upload(gcode) }

      after do
        described_class.delete_file(filename: "test_file.gcode")
        described_class.delete_file(filename: "copied.gcode")
      end

      it { is_expected.to include(origin: "local", path: "copied.gcode") }
    end

    describe "the printer's storage" do
      describe ".upload", vcr: { cassette_name: "files/upload_printer" } do
        use_octoprint_server
        subject(:result) { described_class.upload(gcode, location: printer) }

        its(:done) { is_expected.to be false }
        its("file.origin") { is_expected.to eq Octoprint::Location::Printer }
        its("file.refs.resource") { is_expected.to start_with "#{host}/api/files/printer/" }
      end

      describe ".list", vcr: { cassette_name: "files/storage_printer" } do
        use_octoprint_server
        subject(:storage) { described_class.list(location: printer) }

        its(:key) { is_expected.to eq "printer" }
        its(:usage) { is_expected.to be_nil }
        its(:files) { is_expected.not_to be_empty }
        its(:files) { is_expected.to all(have_attributes(origin: Octoprint::Location::Printer)) }
        its("files.first.refs.resource") { is_expected.to start_with "#{host}/api/files/printer/" }
        its(:name) { is_expected.to eq({ "1.11" => nil, "2.0" => "Printer" }.fetch(version)) }
      end

      describe ".list_all", vcr: { cassette_name: "files/list_all_printer" } do
        use_octoprint_server
        subject(:storages) { described_class.list_all }

        it { is_expected.to include(:local, :printer) }
        it { expect(storages[:printer].key).to eq "printer" }
        it { expect(storages[:printer].files).to all(have_attributes(origin: Octoprint::Location::Printer)) }
      end

      describe ".get", vcr: { cassette_name: "files/get_printer_file" } do
        use_octoprint_server
        subject(:file) { described_class.get(filename: path, location: printer) }

        let(:path) { described_class.list(location: printer).files.first.path }

        it { is_expected.to be_a Octoprint::Files::File }
        its(:origin) { is_expected.to eq Octoprint::Location::Printer }
        its(:path) { is_expected.to eq path }
        its("refs.resource") { is_expected.to eq "#{host}/api/files/printer/#{path}" }
      end

      describe ".delete_file", vcr: { cassette_name: "files/delete_printer_file" } do
        use_octoprint_server
        subject(:delete_file) { described_class.delete_file(filename: path, location: printer) }

        let(:path) { described_class.list(location: printer).files.first.path }

        it { is_expected.to be true }
      end
    end
  end

  on_octoprint_versions("2.0") do
    describe ".copy to another storage", vcr: { cassette_name: "files/copy_to_printer" } do
      use_octoprint_server
      subject(:copy) do
        described_class.copy(filename: "test_file.gcode", destination: "copy.gco", storage: printer)
      end

      before { described_class.upload(gcode) }
      after { described_class.delete_file(filename: "test_file.gcode") }

      it { is_expected.to include(origin: "printer", path: "copy.gco", done: false) }
    end

    describe ".refresh_thumbnails" do
      use_octoprint_server

      before { described_class.upload("spec/files/thumbnail.gcode") }
      after { described_class.delete_file(filename: "thumbnail.gcode") }

      it "refreshes a file's thumbnails", vcr: { cassette_name: "files/refresh_thumbnails/file" } do
        expect(described_class.refresh_thumbnails(filename: "thumbnail.gcode", force: true)).to be true
      end

      it "refreshes every file of the storage", vcr: { cassette_name: "files/refresh_thumbnails/root" } do
        expect(described_class.refresh_thumbnails(recursive: true)).to be true
      end

      it "exposes the extracted thumbnails in the file's refs",
         vcr: { cassette_name: "files/refresh_thumbnails/refs" } do
        refs = described_class.get(filename: "thumbnail.gcode").refs

        expect(refs.thumbnail).to eq "#{host}/downloads/thumbs/local/thumbnail.gcode"
        expect(refs.thumbnails).to eq("16x16" => "#{host}/downloads/thumbs/local/thumbnail.gcode?size=16x16")
      end

      it "raises for a missing file", vcr: { cassette_name: "files/refresh_thumbnails/missing" } do
        expect { described_class.refresh_thumbnails(filename: "missing.gcode") }
          .to raise_error(Octoprint::Exceptions::NotFoundError)
      end

      it "raises for the printer's storage, which has no thumbnails",
         vcr: { cassette_name: "files/refresh_thumbnails/printer" } do
        expect { described_class.refresh_thumbnails(location: printer) }
          .to raise_error(Octoprint::Exceptions::BadRequestError, /Thumbnails are not supported/)
      end
    end
  end

  on_octoprint_versions("1.11") do
    describe "2.0-only features" do
      use_octoprint_server

      it "doesn't copy to another storage" do
        expect { described_class.copy(filename: "a.gcode", destination: "a.gco", storage: printer) }
          .to raise_error(Octoprint::Exceptions::UnsupportedFeatureError, /cross_storage_move/)
      end

      it "doesn't move to another storage" do
        expect { described_class.move(filename: "a.gcode", destination: "a.gco", storage: printer) }
          .to raise_error(Octoprint::Exceptions::UnsupportedFeatureError, /cross_storage_move/)
      end

      it "doesn't refresh thumbnails" do
        expect { described_class.refresh_thumbnails }
          .to raise_error(Octoprint::Exceptions::UnsupportedFeatureError, /refresh_thumbnails/)
      end
    end
  end

  # A client that speaks the 1.11 API (the default) against an OctoPrint 2.0 server
  describe "with the 1.11 API on OctoPrint 2.0", api_version: "1.11", octoprint: "2.0" do
    describe ".list", vcr: { cassette_name: "files/legacy_api/storage_local" } do
      use_octoprint_server
      subject(:storage) { described_class.list }

      before { described_class.upload(gcode) }
      after { described_class.delete_file(filename: "test_file.gcode") }

      its(:key) { is_expected.to eq "local" }
      its(:name) { is_expected.to be_nil }
      its("usage.total") { is_expected.to be_a Integer }
      its("files.first.origin") { is_expected.to eq Octoprint::Location::Local }
    end

    describe ".upload", vcr: { cassette_name: "files/legacy_api/upload_file" } do
      use_octoprint_server
      subject(:result) { described_class.upload(gcode) }

      after { described_class.delete_file(filename: "test_file.gcode") }

      its(:done) { is_expected.to be true }
      its("file.origin") { is_expected.to eq Octoprint::Location::Local }
      its("file.refs.resource") { is_expected.to eq "#{host}/api/files/local/test_file.gcode" }
    end

    describe ".list_all", vcr: { cassette_name: "files/legacy_api/list_all_printer" } do
      use_octoprint_server
      subject(:storages) { described_class.list_all }

      # 2.0 already says "printer" without the header
      it { is_expected.to include(:local, :printer) }
      it { expect(storages[:printer].files).to all(have_attributes(origin: Octoprint::Location::Printer)) }
    end

    # Known limitation: a client pinned to the 1.11 API sends /api/files/sdcard, which OctoPrint 2.0 doesn't serve.
    # Use api_version: :auto or "2.0" for the printer's storage on OctoPrint 2.0.
    describe "the printer's storage", vcr: { cassette_name: "files/legacy_api/storage_printer" } do
      use_octoprint_server

      it "isn't reachable" do
        expect { described_class.list(location: printer) }.to raise_error(Octoprint::Exceptions::NotFoundError)
      end
    end
  end
end
