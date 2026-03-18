# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Push, type: :integration do
  include_context "with default Octoprint config"

  describe ".test", vcr: { cassette_name: "push/test" } do
    use_octoprint_server

    subject(:connected) { described_class.test(session_id: "push_test") }

    it { is_expected.to be_a Hash }

    it "returns version information" do
      expect(connected).to include(:version)
      expect(connected[:version]).to be_a String
    end

    it "returns display version" do
      expect(connected).to include(:display_version)
    end

    it "returns config hash" do
      expect(connected).to include(:config_hash)
    end

    it "returns plugin hash" do
      expect(connected).to include(:plugin_hash)
    end
  end

  describe ".subscribe", vcr: { cassette_name: "push/subscribe" } do
    use_octoprint_server

    subject(:push) { described_class.subscribe(session_id: "push_sub") }

    it { is_expected.to be_a described_class }

    it "has the correct session_id" do
      expect(push.session_id).to eq "push_sub"
    end
  end

  describe "#unsubscribe", vcr: { cassette_name: "push/unsubscribe" } do
    use_octoprint_server

    subject(:result) do
      push = described_class.subscribe(session_id: "push_unsub")
      push.unsubscribe
    end

    it { expect(result).to be true }
  end
end
