# typed: false
# frozen_string_literal: true

RSpec.describe Octoprint::Settings do
  include_context "with default Octoprint config"

  describe "inheritance and configuration" do
    it "inherits from BaseResource" do
      expect(described_class).to be < Octoprint::BaseResource
    end

    it "has correct resource path" do
      expect(described_class.instance_variable_get(:@path)).to eq("/api/settings")
    end
  end

  describe "class method behavior" do
    let(:client) { Octoprint::Client.new(host: "http://test.local", api_key: "test_key") }

    before do
      allow(described_class).to receive(:client).and_return(client)
    end

    describe ".get" do
      let(:settings_data) do
        {
          appearance: {
            name: "OctoPrint",
            color: "default"
          },
          feature: {
            temperature_graph: true,
            g90_influences_extruder: false
          },
          folder: {
            uploads: "uploads",
            timelapse: "timelapse"
          }
        }
      end

      before do
        allow(client).to receive(:request).with("/api/settings", http_method: :get).and_return(settings_data)
      end

      it "fetches settings from the API" do
        expect(client).to receive(:request).with("/api/settings", http_method: :get)
        described_class.get
      end

      it "returns settings as a hash" do
        result = described_class.get
        expect(result).to eq(settings_data)
      end

      it "does not deserialize the response" do
        expect(described_class).not_to receive(:deserialize)
        described_class.get
      end
    end

    describe ".save" do
      let(:settings_to_update) do
        {
          appearance: {
            color: "blue",
            name: "My OctoPrint"
          }
        }
      end

      let(:updated_settings) do
        {
          appearance: {
            name: "My OctoPrint",
            color: "blue"
          },
          feature: {
            temperature_graph: true
          }
        }
      end

      before do
        allow(client).to receive(:request).with(
          "/api/settings",
          http_method: :post,
          body: settings_to_update,
          headers: {},
          options: {}
        ).and_return(updated_settings)
      end

      it "sends a POST request with the settings" do
        expect(client).to receive(:request).with(
          "/api/settings",
          http_method: :post,
          body: settings_to_update,
          headers: {},
          options: {}
        )
        described_class.save(settings_to_update)
      end

      it "returns the updated settings" do
        result = described_class.save(settings_to_update)
        expect(result).to eq(updated_settings)
      end
    end

    describe ".regenerate_api_key" do
      let(:new_api_key_response) do
        {
          api_key: "new_generated_api_key_123456"
        }
      end

      before do
        allow(client).to receive(:request).with(
          "/api/settings/apikey",
          http_method: :post,
          body: {},
          headers: {},
          options: {}
        ).and_return(new_api_key_response)
      end

      it "sends a POST request to the apikey endpoint" do
        expect(client).to receive(:request).with(
          "/api/settings/apikey",
          http_method: :post,
          body: {},
          headers: {},
          options: {}
        )
        described_class.regenerate_api_key
      end

      it "returns the new API key" do
        result = described_class.regenerate_api_key
        expect(result).to eq(new_api_key_response)
        expect(result[:api_key]).to eq("new_generated_api_key_123456")
      end
    end

    describe ".fetch_templates" do
      let(:templates_data) do
        {
          settings: %w[core plugin1 plugin2],
          sidebar: %w[core plugin1],
          navbar: ["core"],
          tab: %w[core plugin1 plugin2 plugin3]
        }
      end

      before do
        allow(client).to receive(:request).with("/api/settings/templates", http_method: :get).and_return(templates_data)
      end

      it "fetches templates from the API" do
        expect(client).to receive(:request).with("/api/settings/templates", http_method: :get)
        described_class.fetch_templates
      end

      it "returns templates as a hash" do
        result = described_class.fetch_templates
        expect(result).to eq(templates_data)
      end

      it "does not deserialize the response" do
        expect(described_class).not_to receive(:deserialize)
        described_class.fetch_templates
      end
    end
  end
end
