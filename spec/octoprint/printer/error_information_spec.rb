# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Printer::ErrorInformation do
  include_context "with default Octoprint config"

  describe "inheritance and configuration" do
    it "inherits from BaseResource" do
      expect(described_class).to be < Octoprint::BaseResource
    end

    it "has correct resource path" do
      expect(described_class.instance_variable_get(:@path)).to eq("/api/printer/error")
    end

    it "includes AutoInitializable and Deserializable" do
      expect(described_class.new).to be_a(Octoprint::AutoInitializable)
      expect(described_class.new).to be_a(Octoprint::Deserializable)
    end
  end

  describe ".get" do
    let(:error_information) { described_class.new(error: "", reason: "") }

    before do
      allow(described_class).to receive(:fetch_resource).and_return(error_information)
    end

    it "fetches the resource with no arguments" do
      described_class.get

      expect(described_class).to have_received(:fetch_resource).with(no_args)
    end

    it "returns the error information" do
      expect(described_class.get).to be(error_information)
    end
  end

  describe ".deserialize" do
    subject(:error_information) { described_class.deserialize(data) }

    context "when there is no error" do
      let(:data) { { error: "", reason: "" } }

      its(:error)       { is_expected.to eq("") }
      its(:reason)      { is_expected.to eq("") }
      its(:consequence) { is_expected.to be_nil }
      its(:faq)         { is_expected.to be_nil }
      its(:logs)        { is_expected.to be_nil }
      its(:extra)       { is_expected.to be_nil }
      its(:error?)      { is_expected.to be(false) }
      its(:faq_url)     { is_expected.to be_nil }
    end

    context "when there is an error" do
      let(:data) do
        {
          error: "MINTEMP triggered!",
          reason: "firmware",
          consequence: "emergency",
          faq: "firmware-mintemp",
          logs: ["Send: M105", "Recv: Error:MINTEMP triggered!"]
        }
      end

      its(:error)       { is_expected.to eq("MINTEMP triggered!") }
      its(:reason)      { is_expected.to eq("firmware") }
      its(:consequence) { is_expected.to eq("emergency") }
      its(:faq)         { is_expected.to eq("firmware-mintemp") }
      its(:logs)        { is_expected.to eq(["Send: M105", "Recv: Error:MINTEMP triggered!"]) }
      its(:extra)       { is_expected.to be_nil }
      its(:error?)      { is_expected.to be(true) }
      its(:faq_url)     { is_expected.to eq("https://faq.octoprint.org/firmware-mintemp") }
    end

    context "when the user lacks the MONITOR_TERMINAL permission" do
      let(:data) { { error: "MINTEMP triggered!", reason: "firmware", consequence: "emergency" } }

      its(:error?) { is_expected.to be(true) }
      its(:logs)   { is_expected.to be_nil }
    end

    context "with unknown fields" do
      let(:data) { { error: "", reason: "", severity: "high" } }

      its(:extra) { is_expected.to eq({ severity: "high" }) }
    end
  end

  describe "#error?" do
    it "is false when error is nil" do
      expect(described_class.new.error?).to be(false)
    end

    it "is false when error is empty" do
      expect(described_class.new(error: "").error?).to be(false)
    end

    it "is true when error has a message" do
      expect(described_class.new(error: "Timeout").error?).to be(true)
    end
  end

  describe "#faq_url" do
    it "is nil when faq is nil" do
      expect(described_class.new.faq_url).to be_nil
    end

    it "is nil when faq is empty" do
      expect(described_class.new(faq: "").faq_url).to be_nil
    end

    it "builds the FAQ link from the faq id" do
      expect(described_class.new(faq: "firmware-mintemp").faq_url).to eq("https://faq.octoprint.org/firmware-mintemp")
    end
  end
end
