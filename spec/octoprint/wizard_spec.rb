# typed: false
# frozen_string_literal: true

RSpec.describe Octoprint::Wizard do
  include_context "with default Octoprint config"

  describe "inheritance and configuration" do
    it "inherits from BaseResource" do
      expect(described_class).to be < Octoprint::BaseResource
    end

    it "has correct resource path" do
      expect(described_class.instance_variable_get(:@path)).to eq("/api/setup/wizard")
    end
  end

  describe "class method behavior" do
    let(:client) { Octoprint::Client.new(host: "http://test.local", api_key: "test_key") }

    before do
      allow(described_class).to receive(:client).and_return(client)
    end

    describe ".get" do
      let(:wizard_data) do
        {
          corewizard: {
            details: { acl: { required: false } },
            ignored: true,
            required: false,
            version: 4
          },
          softwareupdate: {
            details: {},
            ignored: false,
            required: false,
            version: 1
          }
        }
      end

      before do
        allow(client).to receive(:request).with("/api/setup/wizard", http_method: :get).and_return(wizard_data)
      end

      it "fetches wizard data from the API" do
        expect(client).to receive(:request).with("/api/setup/wizard", http_method: :get)
        described_class.get
      end

      it "returns wizard data as a hash" do
        result = described_class.get
        expect(result).to eq(wizard_data)
      end

      it "does not deserialize the response" do
        expect(described_class).not_to receive(:deserialize)
        described_class.get
      end
    end

    describe ".finish" do
      let(:handled_wizards) { %w[corewizard softwareupdate] }

      before do
        allow(client).to receive(:request).with(
          "/api/setup/wizard",
          http_method: :post,
          body: { handled: handled_wizards },
          headers: {},
          options: {}
        ).and_return(true)
      end

      it "sends a POST request with handled wizards" do
        expect(client).to receive(:request).with(
          "/api/setup/wizard",
          http_method: :post,
          body: { handled: handled_wizards },
          headers: {},
          options: {}
        )
        described_class.finish(handled: handled_wizards)
      end

      it "returns true on success" do
        result = described_class.finish(handled: handled_wizards)
        expect(result).to be true
      end
    end
  end
end
