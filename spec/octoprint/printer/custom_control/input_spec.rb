# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Printer::CustomControl::Input do
  describe "modules" do
    subject { described_class.new }

    it { is_expected.to be_a(Octoprint::Deserializable) }
    it { is_expected.to be_a(Octoprint::AutoInitializable) }
  end

  describe ".deserialize" do
    subject(:input) { described_class.deserialize(data) }

    let(:data) do
      { name: "Speed (0-255)", parameter: "speed", default: 255, slider: { min: 0, max: 255, step: 1 } }
    end

    it "deserializes every attribute" do
      expect(input.name).to eq("Speed (0-255)")
      expect(input.parameter).to eq("speed")
      expect(input.default).to eq(255)
      expect(input.slider).to eq({ min: 0, max: 255, step: 1 })
      expect(input.extra).to be_nil
    end

    context "without a slider" do
      let(:data) { { name: "Distance", parameter: "distance", default: "10" } }

      it "keeps a string default and a nil slider" do
        expect(input.default).to eq("10")
        expect(input.slider).to be_nil
      end
    end

    context "with a false slider" do
      let(:data) { { name: "Distance", parameter: "distance", slider: false } }

      it "keeps the false value" do
        expect(input.slider).to be(false)
      end
    end

    context "with unknown fields" do
      let(:data) { { name: "Speed", parameter: "speed", type: "number" } }

      it "collects them in extra" do
        expect(input.extra).to eq({ type: "number" })
      end
    end
  end
end
