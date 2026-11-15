# typed: true
# frozen_string_literal: true

require_relative "../../support/printer_heater_examples"

RSpec.describe Octoprint::Printer::Chamber do
  include_context "with default Octoprint config"

  describe "inheritance and configuration" do
    it "inherits from BaseResource" do
      expect(described_class).to be < Octoprint::BaseResource
    end

    it "has correct resource path" do
      expect(described_class.instance_variable_get(:@path)).to eq("/api/printer/chamber")
    end
  end

  it_behaves_like "a printer heater", :chamber
end
