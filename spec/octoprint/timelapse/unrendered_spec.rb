# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Timelapse::Unrendered do
  describe "modules" do
    subject { described_class.new }

    it { is_expected.to be_a(Octoprint::Deserializable) }
    it { is_expected.to be_a(Octoprint::AutoInitializable) }
  end

  describe ".deserialize" do
    subject(:job) { described_class.deserialize(data) }

    let(:data) do
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
    end

    it "deserializes the attributes" do
      expect(job.name).to eq("benchy_20261115")
      expect(job.count).to eq(3)
      expect(job.size).to eq("900.0B")
      expect(job.bytes).to eq(900)
      expect(job.date).to eq("2026-11-15 00:52")
    end

    it "deserializes the status flags" do
      expect(job.recording).to be(false)
      expect(job.rendering).to be(false)
      expect(job.processing).to be(false)
    end

    it "has no extra fields" do
      expect(job.extra).to be_nil
    end

    context "when the job is being rendered" do
      let(:data) { { name: "cube_20261115", recording: false, rendering: true, processing: true } }

      it "deserializes the true flags" do
        expect(job.recording).to be(false)
        expect(job.rendering).to be(true)
        expect(job.processing).to be(true)
      end

      it "leaves the count unset" do
        expect(job.count).to be_nil
      end
    end

    context "with unknown fields" do
      let(:data) { { name: "benchy_20261115", count: 3, progress: 42 } }

      it "collects them in extra" do
        expect(job.extra).to eq({ progress: 42 })
      end
    end
  end
end
