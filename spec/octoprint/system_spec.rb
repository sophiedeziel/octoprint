# typed: false
# frozen_string_literal: true

RSpec.describe Octoprint::System do
  include_context "with default Octoprint config"

  describe "inheritance" do
    it "inherits from BaseResource" do
      expect(described_class).to be < Octoprint::BaseResource
    end
  end

  describe ".resource_path" do
    it "sets the correct API endpoint" do
      expect(described_class.instance_variable_get(:@path)).to eq("/api/system")
    end
  end

  describe ".commands" do
    let(:commands_response) { Octoprint::System::Commands.new(core: [], custom: []) }

    before do
      allow(Octoprint::System::Commands).to receive(:list).and_return(commands_response)
    end

    it "delegates to Commands.list" do
      expect(described_class.commands).to eq(commands_response)
      expect(Octoprint::System::Commands).to have_received(:list)
    end
  end
end
