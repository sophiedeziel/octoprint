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

    subject { described_class.upload("spec/files/test_file.gcode", location: :local) }

    it { is_expected.to be_a Hash }
    its(:keys) { are_expected.to eq %i[done files] }
    its([:done]) { is_expected.to be true }
  end
end
