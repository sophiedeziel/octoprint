# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Wizard, type: :integration do
  include_context "with default Octoprint config"

  describe ".get", vcr: { cassette_name: "wizard/get" } do
    use_octoprint_server

    subject(:wizards) { described_class.get }

    it { is_expected.to be_a Hash }

    it "returns wizard entries" do
      expect(wizards).not_to be_empty
    end

    it "returns wizard data with expected fields" do
      wizards.each_value do |entry|
        expect(entry).to include(:required)
        expect(entry).to include(:ignored)
        expect(entry).to include(:details)
        expect(entry).to have_key(:version)
      end
    end
  end

  describe ".finish", vcr: { cassette_name: "wizard/finish" } do
    use_octoprint_server

    subject(:finish_wizard) { described_class.finish(handled: ["corewizard"]) }

    it { expect(finish_wizard).to be true }
  end
end
