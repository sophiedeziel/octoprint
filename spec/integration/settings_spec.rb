# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Settings, type: :integration do
  include_context "with default Octoprint config"

  describe ".get", vcr: { cassette_name: "settings/get" } do
    use_octoprint_server

    subject(:settings) { described_class.get }

    it { is_expected.to be_a Hash }

    it "returns settings structure" do
      expect(settings).to include(:api)
      expect(settings).to include(:appearance)
      expect(settings).to include(:controls)
      expect(settings).to include(:devel)
      expect(settings).to include(:feature)
      expect(settings).to include(:folder)
      expect(settings).to include(:plugins)
      expect(settings).to include(:scripts)
      expect(settings).to include(:serial)
      expect(settings).to include(:server)
      expect(settings).to include(:system)
      expect(settings).to include(:temperature)
      expect(settings).to include(:webcam)
    end

    it "returns appearance settings" do
      expect(settings[:appearance]).to include(:name)
      expect(settings[:appearance]).to include(:color)
    end

    it "returns feature flags" do
      expect(settings[:feature]).to be_a Hash
    end
  end

  describe ".save", vcr: { cassette_name: "settings/save" } do
    use_octoprint_server

    subject(:updated_settings) do
      described_class.save(
        appearance: {
          color: "blue",
          name: "New Name"
        }
      )
    end

    let!(:previous_settings) { described_class.get }

    after do
      described_class.save(previous_settings)
    end

    it { is_expected.to be_a Hash }

    it "returns updated settings" do
      expect(updated_settings).to include(:appearance)
      expect(updated_settings[:appearance][:color]).to eq("blue")
      expect(updated_settings[:appearance][:name]).to eq("New Name")
    end

    it "preserves other settings" do
      expect(updated_settings[:feature]).to eq(previous_settings[:feature])
      expect(updated_settings[:folder]).to eq(previous_settings[:folder])
      expect(updated_settings[:system]).to eq(previous_settings[:system])
    end
  end

  describe ".save with partial update", vcr: { cassette_name: "settings/save_partial" } do
    use_octoprint_server

    subject(:partial_update) do
      described_class.save(
        appearance: {
          color: "green"
        }
      )
    end

    it "updates only specified fields" do
      expect(partial_update[:appearance][:color]).to eq("green")
      expect(partial_update[:appearance][:name]).to be_present
    end
  end

  describe ".regenerate_api_key", vcr: { cassette_name: "settings/regenerate_api_key" } do
    use_octoprint_server

    subject(:api_key_result) { described_class.regenerate_api_key }

    it { is_expected.to be_a Hash }

    it "returns new API key" do
      expect(api_key_result).to include(:apikey)
      expect(api_key_result[:apikey]).to be_a String
      expect(api_key_result[:apikey]).not_to be_empty
    end

    it "returns a different key than the current one", vcr: { cassette_name: "settings/regenerate_api_key_twice" } do
      previous_key = described_class.regenerate_api_key[:apikey]
      expect(api_key_result[:apikey]).not_to eq previous_key
    end
  end

  describe ".fetch_templates", vcr: { cassette_name: "settings/fetch_templates" } do
    use_octoprint_server

    subject(:templates) { described_class.fetch_templates }

    it { is_expected.to be_a Hash }

    it "returns template component identifiers" do
      # The exact structure depends on the OctoPrint installation
      # but it should return a hash with component identifiers. This is tested using a vanilla octoprint instance
      expect(templates).to include(:order)
      expect(templates[:order]).to include(:about)
      expect(templates[:order]).to include(:generic)
    end
  end
end
