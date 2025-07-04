# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Files do
  include_context "with default Octoprint config"

  describe "The empty files container" do
    subject { described_class.new(files: [], free: 1000, total: 3000) }

    its(:files) { are_expected.to eq [] }
    its(:free) { is_expected.to eq 1000 }
    its(:total) { is_expected.to eq 3000 }
  end

  describe "Parameter validation" do
    it "raises TypeError for invalid location parameter" do
      expect do
        described_class.upload("test.gcode", location: "invalid")
      end.to raise_error(TypeError, /Parameter 'location': Expected type Octoprint::Location, got type/)
    end
  end
end
