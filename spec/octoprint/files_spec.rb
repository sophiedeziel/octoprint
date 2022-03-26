# frozen_string_literal: true

RSpec.describe Octoprint::Files do
  include_context "Octoprint config"

  describe "The empty files container" do
    subject { Octoprint::Files.new(files: [], free: 1000, total: 3000) }

    its(:files) { are_expected.to eq [] }
    its(:free) { is_expected.to eq 1000 }
    its(:total) { is_expected.to eq 3000 }
  end

  describe "Get file list from server", vcr: { cassette_name: "files/list" } do
    use_octoprint_server

    subject { Octoprint::Files.list }

    it { is_expected.to be_a Octoprint::Files }
    its(:files) { are_expected.to be_a Array }
    its(:free) { is_expected.to eq 205_266_227_200 }
    its(:total) { is_expected.to eq 250_685_575_168 }
  end
end
