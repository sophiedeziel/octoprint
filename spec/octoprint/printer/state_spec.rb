# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Printer::State do
  describe "modules" do
    subject { described_class.new }

    it { is_expected.to be_a(Octoprint::Deserializable) }
    it { is_expected.to be_a(Octoprint::AutoInitializable) }
  end

  describe ".deserialize" do
    subject(:state) { described_class.deserialize(data) }

    let(:data) do
      {
        text: "Operational",
        flags: {
          operational: true,
          paused: false,
          printing: false,
          cancelling: false,
          pausing: false,
          sd_ready: true,
          error: false,
          ready: true,
          closed_or_error: false
        }
      }
    end

    it "deserializes the text" do
      expect(state.text).to eq("Operational")
    end

    it "deserializes the flags" do
      expect(state.flags).to be_a(Octoprint::Printer::StateFlags)
      expect(state.flags.operational).to be(true)
      expect(state.flags.sd_ready).to be(true)
      expect(state.flags.closed_or_error).to be(false)
    end

    it "has no error or extra fields" do
      expect(state.error).to be_nil
      expect(state.extra).to be_nil
    end

    context "with an error" do
      let(:data) do
        { text: "Offline after error", error: "Too many consecutive timeouts", flags: { error: true } }
      end

      it "deserializes the error message" do
        expect(state.error).to eq("Too many consecutive timeouts")
        expect(state.flags.error).to be(true)
      end
    end

    context "without flags" do
      let(:data) { { text: "Offline" } }

      it "has nil flags" do
        expect(state.flags).to be_nil
      end
    end

    context "with unknown fields" do
      let(:data) { { text: "Operational", flags: { ready: true }, color: "green" } }

      it "collects them in extra" do
        expect(state.extra).to eq({ color: "green" })
      end
    end
  end
end
