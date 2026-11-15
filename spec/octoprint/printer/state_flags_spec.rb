# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Printer::StateFlags do
  describe "modules" do
    subject { described_class.new }

    it { is_expected.to be_a(Octoprint::Deserializable) }
    it { is_expected.to be_a(Octoprint::AutoInitializable) }
  end

  describe ".deserialize" do
    subject(:flags) { described_class.deserialize(data) }

    let(:data) do
      {
        operational: true,
        paused: false,
        printing: true,
        pausing: false,
        cancelling: false,
        resuming: false,
        finishing: false,
        sd_ready: true,
        error: false,
        ready: false,
        closed_or_error: false
      }
    end

    it "deserializes every flag" do
      expect(flags.operational).to be(true)
      expect(flags.paused).to be(false)
      expect(flags.printing).to be(true)
      expect(flags.pausing).to be(false)
      expect(flags.cancelling).to be(false)
      expect(flags.resuming).to be(false)
      expect(flags.finishing).to be(false)
      expect(flags.sd_ready).to be(true)
      expect(flags.error).to be(false)
      expect(flags.ready).to be(false)
      expect(flags.closed_or_error).to be(false)
    end

    it "has no extra fields" do
      expect(flags.extra).to be_nil
    end

    context "with camelCase keys" do
      let(:data) { { sdReady: true, closedOrError: true } }

      it "converts them to snake_case" do
        expect(flags.sd_ready).to be(true)
        expect(flags.closed_or_error).to be(true)
      end
    end

    context "when the optional flags are missing" do
      let(:data) { { operational: true, ready: true } }

      it "leaves them nil" do
        expect(flags.resuming).to be_nil
        expect(flags.finishing).to be_nil
      end
    end

    context "with unknown flags" do
      let(:data) { { operational: true, connecting: false } }

      it "collects them in extra" do
        expect(flags.extra).to eq({ connecting: false })
      end
    end
  end
end
