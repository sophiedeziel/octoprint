# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Timelapse::Config do
  describe "modules" do
    subject { described_class.new }

    it { is_expected.to be_a(Octoprint::Deserializable) }
    it { is_expected.to be_a(Octoprint::AutoInitializable) }
  end

  describe ".deserialize" do
    subject(:config) { described_class.deserialize(data) }

    context "with a timed config" do
      let(:data) { { type: "timed", post_roll: 0, fps: 25, render_after_print: "always", interval: 10 } }

      it "deserializes the attributes" do
        expect(config.type).to eq("timed")
        expect(config.post_roll).to eq(0)
        expect(config.fps).to eq(25)
        expect(config.render_after_print).to eq("always")
        expect(config.interval).to eq(10)
      end

      it "leaves the zchange attributes unset" do
        expect(config.retraction_z_hop).to be_nil
        expect(config.min_delay).to be_nil
      end

      it "has no extra fields" do
        expect(config.extra).to be_nil
      end
    end

    context "with a zchange config" do
      let(:data) do
        { type: "zchange", post_roll: 5, fps: 30, render_after_print: "success", retraction_z_hop: 0.4, min_delay: 5.0 }
      end

      it "deserializes the zchange attributes" do
        expect(config.type).to eq("zchange")
        expect(config.retraction_z_hop).to eq(0.4)
        expect(config.min_delay).to eq(5.0)
      end

      it "leaves the interval unset" do
        expect(config.interval).to be_nil
      end
    end

    context "with an off config" do
      let(:data) { { type: "off" } }

      it "only sets the type" do
        expect(config.type).to eq("off")
        expect(config.post_roll).to be_nil
        expect(config.fps).to be_nil
        expect(config.render_after_print).to be_nil
      end
    end

    context "with camelCase keys" do
      let(:data) { { type: "zchange", postRoll: 5, minDelay: 5.0, renderAfterPrint: "never" } }

      it "converts them to snake_case" do
        expect(config.post_roll).to eq(5)
        expect(config.min_delay).to eq(5.0)
        expect(config.render_after_print).to eq("never")
      end
    end

    context "with unknown fields" do
      let(:data) { { type: "timed", interval: 10, capture_post_roll: true } }

      it "collects them in extra" do
        expect(config.extra).to eq({ capture_post_roll: true })
      end
    end
  end

  describe "#off?" do
    it "is true when the type is off" do
      expect(described_class.new(type: "off")).to be_off
    end

    it "is false when the type is zchange" do
      expect(described_class.new(type: "zchange")).not_to be_off
    end

    it "is false when the type is timed" do
      expect(described_class.new(type: "timed")).not_to be_off
    end

    it "is false when the type is missing" do
      expect(described_class.new).not_to be_off
    end
  end
end
