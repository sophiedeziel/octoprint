# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Timelapse::Rendered do
  describe "modules" do
    subject { described_class.new }

    it { is_expected.to be_a(Octoprint::Deserializable) }
    it { is_expected.to be_a(Octoprint::AutoInitializable) }
  end

  describe ".deserialize" do
    subject(:file) { described_class.deserialize(data) }

    let(:data) do
      {
        name: "sample_print_20261115.mp4",
        size: "2.0KB",
        bytes: 2048,
        date: "2026-11-15 00:52",
        timestamp: 1_794_721_955.893133,
        url: "/downloads/timelapse/sample_print_20261115.mp4",
        thumbnail: "/downloads/timelapse/sample_print_20261115.mp4.thumb.jpg"
      }
    end

    it "deserializes the attributes" do
      expect(file.name).to eq("sample_print_20261115.mp4")
      expect(file.size).to eq("2.0KB")
      expect(file.bytes).to eq(2048)
      expect(file.date).to eq("2026-11-15 00:52")
      expect(file.timestamp).to eq(1_794_721_955.893133)
      expect(file.url).to eq("/downloads/timelapse/sample_print_20261115.mp4")
      expect(file.thumbnail).to eq("/downloads/timelapse/sample_print_20261115.mp4.thumb.jpg")
    end

    it "has no extra fields" do
      expect(file.extra).to be_nil
    end

    context "without a thumbnail" do
      let(:data) do
        { name: "benchy.mp4", size: "1.0MB", bytes: 1_048_576, date: "2026-11-15 00:52",
          url: "/downloads/timelapse/benchy.mp4" }
      end

      it "leaves the thumbnail and timestamp unset" do
        expect(file.thumbnail).to be_nil
        expect(file.timestamp).to be_nil
      end
    end

    context "with unknown fields" do
      let(:data) { { name: "benchy.mp4", url: "/downloads/timelapse/benchy.mp4", origin: "local" } }

      it "collects them in extra" do
        expect(file.extra).to eq({ origin: "local" })
      end
    end
  end

  describe "#modification_time" do
    it "converts the timestamp to a Time" do
      file = described_class.new(timestamp: 1_794_721_955.893133)

      expect(file.modification_time).to be_a(Time)
      expect(file.modification_time).to eq(Time.at(1_794_721_955.893133))
    end

    it "is nil when the timestamp is missing" do
      expect(described_class.new.modification_time).to be_nil
    end
  end
end
