# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Timelapse do
  include_context "with default Octoprint config"

  # The HTTP client already converts camelCase keys to snake_case
  let(:response) do
    {
      config: { type: "timed", post_roll: 0, fps: 25, render_after_print: "always", interval: 10 },
      enabled: true,
      files: [
        {
          name: "sample_print_20261115.mp4",
          size: "2.0KB",
          bytes: 2048,
          date: "2026-11-15 00:52",
          timestamp: 1_794_721_955.893133,
          url: "/downloads/timelapse/sample_print_20261115.mp4",
          thumbnail: "/downloads/timelapse/sample_print_20261115.mp4.thumb.jpg"
        }
      ]
    }
  end

  let(:unrendered_response) do
    response.merge(
      unrendered: [
        {
          name: "benchy_20261115",
          count: 3,
          size: "900.0B",
          bytes: 900,
          date: "2026-11-15 00:52",
          recording: false,
          rendering: false,
          processing: false
        }
      ]
    )
  end

  describe "inheritance and configuration" do
    it "inherits from BaseResource" do
      expect(described_class).to be < Octoprint::BaseResource
    end

    it "has correct resource path" do
      expect(described_class.instance_variable_get(:@path)).to eq("/api/timelapse")
    end

    it "includes AutoInitializable and Deserializable" do
      expect(described_class.new).to be_a(Octoprint::AutoInitializable)
      expect(described_class.new).to be_a(Octoprint::Deserializable)
    end

    it "lists the supported timelapse types" do
      expect(described_class::TYPES).to eq(%w[off zchange timed])
      expect(described_class::TYPES).to be_frozen
    end
  end

  describe ".list" do
    let(:timelapse) { described_class.new(enabled: true, files: []) }

    before do
      allow(described_class).to receive(:fetch_resource).and_return(timelapse)
    end

    it "fetches the resource without query options by default" do
      described_class.list

      expect(described_class).to have_received(:fetch_resource).with(options: {})
    end

    it "requests the unrendered timelapses" do
      described_class.list(unrendered: true)

      expect(described_class).to have_received(:fetch_resource).with(options: { unrendered: true })
    end

    it "forces a refresh of the list" do
      described_class.list(force: true)

      expect(described_class).to have_received(:fetch_resource).with(options: { force: true })
    end

    it "combines the unrendered and force options" do
      described_class.list(unrendered: true, force: true)

      expect(described_class).to have_received(:fetch_resource).with(options: { unrendered: true, force: true })
    end

    it "omits options that are explicitly false" do
      described_class.list(unrendered: false, force: false)

      expect(described_class).to have_received(:fetch_resource).with(options: {})
    end

    it "returns the timelapse list" do
      expect(described_class.list).to be(timelapse)
    end
  end

  describe ".delete_file" do
    before do
      allow(described_class).to receive(:delete).and_return(response)
    end

    it "deletes the timelapse file" do
      described_class.delete_file(filename: "sample_print_20261115.mp4")

      expect(described_class).to have_received(:delete).with(path: "/api/timelapse/sample_print_20261115.mp4")
    end

    it "appends the unrendered query when requested" do
      described_class.delete_file(filename: "sample_print_20261115.mp4", unrendered: true)

      expect(described_class).to have_received(:delete)
        .with(path: "/api/timelapse/sample_print_20261115.mp4?unrendered=true")
    end

    it "percent-encodes the file name" do
      described_class.delete_file(filename: "My Part #2_20261115.mp4")

      expect(described_class).to have_received(:delete).with(path: "/api/timelapse/My%20Part%20%232_20261115.mp4")
    end

    it "returns the deserialized timelapse list" do
      result = described_class.delete_file(filename: "sample_print_20261115.mp4")

      expect(result).to be_a(described_class)
      expect(result.config).to be_a(described_class::Config)
      expect(result.files).to all(be_a(described_class::Rendered))
    end
  end

  describe ".issue_unrendered_command" do
    before do
      allow(described_class).to receive(:post).and_return(true)
    end

    it "posts the command to the unrendered timelapse" do
      described_class.issue_unrendered_command(name: "benchy_20261115", command: "render")

      expect(described_class).to have_received(:post)
        .with(path: "/api/timelapse/unrendered/benchy_20261115", params: { command: "render" })
    end

    it "percent-encodes the name" do
      described_class.issue_unrendered_command(name: "My Part #2_20261115", command: "render")

      expect(described_class).to have_received(:post)
        .with(path: "/api/timelapse/unrendered/My%20Part%20%232_20261115", params: { command: "render" })
    end

    it "returns the post result" do
      expect(described_class.issue_unrendered_command(name: "benchy_20261115", command: "render")).to be(true)
    end
  end

  describe ".render" do
    before do
      allow(described_class).to receive(:issue_unrendered_command).and_return(true)
    end

    it "delegates to issue_unrendered_command with render" do
      described_class.render(name: "benchy_20261115")

      expect(described_class).to have_received(:issue_unrendered_command)
        .with(name: "benchy_20261115", command: "render")
    end

    it "returns the command result" do
      expect(described_class.render(name: "benchy_20261115")).to be(true)
    end
  end

  describe ".delete_unrendered" do
    before do
      allow(described_class).to receive(:delete).and_return(true)
    end

    it "deletes the unrendered timelapse" do
      described_class.delete_unrendered(name: "benchy_20261115")

      expect(described_class).to have_received(:delete).with(path: "/api/timelapse/unrendered/benchy_20261115")
    end

    it "percent-encodes the name so the server glob only matches that job" do
      described_class.delete_unrendered(name: "Part#2_20261115")

      expect(described_class).to have_received(:delete).with(path: "/api/timelapse/unrendered/Part%232_20261115")
    end

    it "returns the delete result" do
      expect(described_class.delete_unrendered(name: "benchy_20261115")).to be(true)
    end
  end

  describe ".update_config" do
    before do
      allow(described_class).to receive(:post).and_return(response)
    end

    it "posts only the type when no settings are given" do
      described_class.update_config(type: "off")

      expect(described_class).to have_received(:post).with(path: "/api/timelapse", params: { type: "off" })
    end

    it "sends the timed settings" do
      described_class.update_config(type: "timed", interval: 10, fps: 30, post_roll: 5)

      expect(described_class).to have_received(:post)
        .with(path: "/api/timelapse", params: { type: "timed", postRoll: 5, fps: 30, interval: 10 })
    end

    it "accepts whole numbers for the zchange float settings" do
      described_class.update_config(type: "zchange", retraction_z_hop: 0, min_delay: 5)

      expect(described_class).to have_received(:post)
        .with(path: "/api/timelapse", params: { type: "zchange", retractionZHop: 0, minDelay: 5 })
    end

    it "sends the zchange settings in camelCase" do
      described_class.update_config(type: "zchange", retraction_z_hop: 0.4, min_delay: 5.0,
                                    render_after_print: "success")

      expect(described_class).to have_received(:post).with(
        path: "/api/timelapse",
        params: { type: "zchange", retractionZHop: 0.4, minDelay: 5.0, renderAfterPrint: "success" }
      )
    end

    it "sends every setting when all are given" do
      described_class.update_config(type: "zchange", post_roll: 5, fps: 30, interval: 10, retraction_z_hop: 0.4,
                                    min_delay: 5.0, render_after_print: "never", save: true)

      expect(described_class).to have_received(:post).with(
        path: "/api/timelapse",
        params: {
          type: "zchange", postRoll: 5, fps: 30, interval: 10, retractionZHop: 0.4, minDelay: 5.0,
          renderAfterPrint: "never", save: true
        }
      )
    end

    it "sends save when it is true" do
      described_class.update_config(type: "timed", save: true)

      expect(described_class).to have_received(:post)
        .with(path: "/api/timelapse", params: { type: "timed", save: true })
    end

    it "omits save when it is false" do
      described_class.update_config(type: "timed", save: false)

      expect(described_class).to have_received(:post).with(path: "/api/timelapse", params: { type: "timed" })
    end

    it "appends the unrendered query when requested" do
      described_class.update_config(type: "off", unrendered: true)

      expect(described_class).to have_received(:post)
        .with(path: "/api/timelapse?unrendered=true", params: { type: "off" })
    end

    it "accepts every supported type" do
      # Deserialization mutates the response, so each call needs a fresh copy
      allow(described_class).to receive(:post) { response.deep_dup }

      described_class::TYPES.each do |type|
        described_class.update_config(type: type)

        expect(described_class).to have_received(:post).with(path: "/api/timelapse", params: { type: type })
      end
    end

    it "returns the deserialized timelapse list" do
      allow(described_class).to receive(:post).and_return(unrendered_response)

      result = described_class.update_config(type: "timed", interval: 10, unrendered: true)

      expect(result).to be_a(described_class)
      expect(result.config.interval).to eq(10)
      expect(result.unrendered).to all(be_a(described_class::Unrendered))
    end

    context "with an unknown type" do
      it "raises an ArgumentError" do
        expect { described_class.update_config(type: "snapshot") }
          .to raise_error(ArgumentError, "type must be one of off, zchange, timed")
      end

      it "does not post the config" do
        expect { described_class.update_config(type: "snapshot") }.to raise_error(ArgumentError)

        expect(described_class).not_to have_received(:post)
      end
    end
  end

  describe ".deserialize" do
    subject(:timelapse) { described_class.deserialize(data) }

    let(:data) { unrendered_response }

    it "deserializes the enabled flag" do
      expect(timelapse.enabled).to be(true)
    end

    it "deserializes the config" do
      expect(timelapse.config).to be_a(described_class::Config)
      expect(timelapse.config.type).to eq("timed")
      expect(timelapse.config.post_roll).to eq(0)
      expect(timelapse.config.fps).to eq(25)
      expect(timelapse.config.render_after_print).to eq("always")
      expect(timelapse.config.interval).to eq(10)
    end

    it "deserializes the rendered files" do
      file = timelapse.files.first

      expect(timelapse.files.length).to eq(1)
      expect(file).to be_a(described_class::Rendered)
      expect(file.name).to eq("sample_print_20261115.mp4")
      expect(file.size).to eq("2.0KB")
      expect(file.bytes).to eq(2048)
      expect(file.timestamp).to eq(1_794_721_955.893133)
      expect(file.url).to eq("/downloads/timelapse/sample_print_20261115.mp4")
      expect(file.thumbnail).to eq("/downloads/timelapse/sample_print_20261115.mp4.thumb.jpg")
    end

    it "deserializes the unrendered timelapses" do
      job = timelapse.unrendered.first

      expect(timelapse.unrendered.length).to eq(1)
      expect(job).to be_a(described_class::Unrendered)
      expect(job.name).to eq("benchy_20261115")
      expect(job.count).to eq(3)
      expect(job.bytes).to eq(900)
      expect(job.processing).to be(false)
    end

    it "has no extra fields at any level" do
      expect(timelapse.extra).to be_nil
      expect(timelapse.config.extra).to be_nil
      expect(timelapse.files.first.extra).to be_nil
      expect(timelapse.unrendered.first.extra).to be_nil
    end

    context "with a zchange config" do
      let(:data) do
        response.merge(
          config: { type: "zchange", post_roll: 0, fps: 25, render_after_print: "success", retraction_z_hop: 0.4,
                    min_delay: 5.0 }
        )
      end

      it "deserializes the zchange settings" do
        expect(timelapse.config.retraction_z_hop).to eq(0.4)
        expect(timelapse.config.min_delay).to eq(5.0)
        expect(timelapse.config.interval).to be_nil
      end
    end

    context "without unrendered timelapses" do
      let(:data) { response }

      it "leaves unrendered nil" do
        expect(timelapse.unrendered).to be_nil
      end
    end

    context "without any files" do
      let(:data) { response.merge(files: [], unrendered: []) }

      it "returns empty arrays" do
        expect(timelapse.files).to eq([])
        expect(timelapse.unrendered).to eq([])
      end
    end

    context "with unknown fields at every level" do
      let(:data) do
        {
          config: { type: "off", capture_post_roll: true },
          enabled: false,
          files: [{ name: "benchy.mp4", url: "/downloads/timelapse/benchy.mp4", origin: "local" }],
          unrendered: [{ name: "benchy_20261115", progress: 42 }],
          free_space: 1_000_000
        }
      end

      it "collects them in extra" do
        expect(timelapse.extra).to eq({ free_space: 1_000_000 })
        expect(timelapse.config.extra).to eq({ capture_post_roll: true })
        expect(timelapse.files.first.extra).to eq({ origin: "local" })
        expect(timelapse.unrendered.first.extra).to eq({ progress: 42 })
      end
    end
  end
end
