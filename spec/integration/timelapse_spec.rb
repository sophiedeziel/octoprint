# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Timelapse, type: :integration do
  include_context "with default Octoprint config"
  use_octoprint_server

  describe ".list" do
    context "without unrendered timelapses", vcr: { cassette_name: "timelapse/list" } do
      subject(:timelapse) { described_class.list }

      it { is_expected.to be_a described_class }
      its(:enabled)    { is_expected.to be true }
      its(:unrendered) { is_expected.to be_nil }
      its(:extra)      { is_expected.to be_nil }

      it "returns the current config" do
        expect(timelapse.config).to be_a Octoprint::Timelapse::Config
        expect(timelapse.config.type).to eq "off"
        expect(timelapse.config).to be_off
      end

      it "returns the rendered timelapses" do
        expect(timelapse.files.map(&:name)).to contain_exactly("old_print_20261101.mp4", "sample_print_20261115.mp4")
        expect(timelapse.files).to all(be_a Octoprint::Timelapse::Rendered)
      end

      it "returns the details of a rendered timelapse" do
        file = timelapse.files.find { |f| f.name == "sample_print_20261115.mp4" }

        expect(file).to have_attributes(
          size: "2.0KB",
          bytes: 2048,
          url: "/downloads/timelapse/sample_print_20261115.mp4",
          thumbnail: "/downloads/timelapse/sample_print_20261115.mp4.thumb.jpg",
          extra: nil
        )
        expect(file.date).to be_a String
        expect(file.modification_time).to be_a Time
      end

      it "omits the thumbnail when there is none" do
        expect(timelapse.files.find { |f| f.name == "old_print_20261101.mp4" }.thumbnail).to be_nil
      end
    end

    context "with unrendered timelapses", vcr: { cassette_name: "timelapse/list_unrendered" } do
      subject(:timelapse) { described_class.list(unrendered: true) }

      it "returns the unrendered timelapses" do
        expect(timelapse.unrendered.map(&:name)).to eq %w[benchy_20261115 stale_job]
        expect(timelapse.unrendered).to all(be_a Octoprint::Timelapse::Unrendered)
      end

      it "returns the details of an unrendered timelapse" do
        expect(timelapse.unrendered.first).to have_attributes(
          count: 3, size: "900.0B", bytes: 900,
          recording: false, rendering: false, processing: false, extra: nil
        )
      end
    end

    context "when forcing a refresh", vcr: { cassette_name: "timelapse/list_force" } do
      subject(:timelapse) { described_class.list(force: true) }

      its(:files) { is_expected.to all(be_a Octoprint::Timelapse::Rendered) }
    end
  end

  describe ".update_config" do
    context "with a timed timelapse", vcr: { cassette_name: "timelapse/update_config_timed" } do
      subject(:config) do
        described_class.update_config(type: "timed", interval: 10, fps: 30, post_roll: 5,
                                      render_after_print: "success").config
      end

      it "returns the new config" do
        expect(config).to have_attributes(type: "timed", interval: 10, fps: 30, post_roll: 5,
                                          render_after_print: "success", extra: nil)
      end
    end

    context "with a Z-change timelapse", vcr: { cassette_name: "timelapse/update_config_zchange" } do
      subject(:config) { described_class.update_config(type: "zchange", retraction_z_hop: 0.4, min_delay: 2.5).config }

      it "returns the new config" do
        expect(config).to have_attributes(type: "zchange", retraction_z_hop: 0.4, min_delay: 2.5,
                                          fps: 25, post_roll: 0, render_after_print: "always")
      end
    end

    context "when saving the config", vcr: { cassette_name: "timelapse/update_config_save" } do
      subject(:timelapse) { described_class.update_config(type: "off", save: true, unrendered: true) }

      its(:config)     { is_expected.to be_off }
      its(:unrendered) { is_expected.to all(be_a Octoprint::Timelapse::Unrendered) }
    end

    context "with an invalid setting", vcr: { cassette_name: "timelapse/update_config_invalid" } do
      it "raises a bad request error" do
        expect { described_class.update_config(type: "timed", fps: 0) }
          .to raise_error(Octoprint::Exceptions::BadRequestError, /fps is invalid/)
      end
    end
  end

  describe ".render", vcr: { cassette_name: "timelapse/render" } do
    it "renders the unrendered timelapse" do
      expect(described_class.render(name: "benchy_20261115")).to be true
    end
  end

  describe ".issue_unrendered_command" do
    context "with an unknown command", vcr: { cassette_name: "timelapse/unrendered_command_invalid" } do
      it "raises a bad request error" do
        expect { described_class.issue_unrendered_command(name: "benchy_20261115", command: "explode") }
          .to raise_error(Octoprint::Exceptions::BadRequestError)
      end
    end
  end

  describe ".delete_unrendered", vcr: { cassette_name: "timelapse/delete_unrendered" } do
    it "deletes the unrendered timelapse" do
      expect(described_class.delete_unrendered(name: "stale_job")).to be true
    end
  end

  describe ".delete_file", vcr: { cassette_name: "timelapse/delete_file" } do
    subject(:timelapse) { described_class.delete_file(filename: "old_print_20261101.mp4", unrendered: true) }

    it "returns the updated timelapse list" do
      expect(timelapse.files.map(&:name)).to eq ["sample_print_20261115.mp4"]
      expect(timelapse.unrendered.map(&:name)).to eq ["benchy_20261115"]
    end
  end
end
