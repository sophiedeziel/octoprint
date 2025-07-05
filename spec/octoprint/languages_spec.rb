# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Languages do
  include_context "with default Octoprint config"

  describe "#initialize" do
    let(:language_pack_data) do
      {
        _core: {
          identifier: "_core",
          display: "Core",
          languages: []
        },
        plugin_test: {
          identifier: "plugin_test",
          display: "Test Plugin",
          languages: %w[en de]
        }
      }
    end

    it "creates LanguagePack objects from language pack data" do
      # Use deserialize to simulate API response
      languages = described_class.deserialize(language_packs: language_pack_data)

      expect(languages.language_packs).to be_a(Hash)
      expect(languages.language_packs.keys).to contain_exactly(:_core, :plugin_test)

      # Check core pack
      core_pack = languages.language_packs[:_core]
      expect(core_pack).to be_a(Octoprint::Languages::LanguagePack)
      expect(core_pack.identifier).to eq("_core")
      expect(core_pack.display).to eq("Core")
      expect(core_pack.languages).to eq([])

      # Check plugin pack
      plugin_pack = languages.language_packs[:plugin_test]
      expect(plugin_pack).to be_a(Octoprint::Languages::LanguagePack)
      expect(plugin_pack.identifier).to eq("plugin_test")
      expect(plugin_pack.display).to eq("Test Plugin")
      expect(plugin_pack.languages).to eq(%w[en de])
    end

    it "handles empty language packs" do
      languages = described_class.new(language_packs: {})

      expect(languages.language_packs).to eq({})
    end
  end

  describe "inheritance and configuration" do
    it "inherits from BaseResource" do
      expect(described_class).to be < Octoprint::BaseResource
    end

    it "includes AutoInitializable" do
      expect(described_class).to include(Octoprint::AutoInitializable)
    end

    it "includes Deserializable" do
      expect(described_class).to include(Octoprint::Deserializable)
    end

    it "has correct resource path" do
      expect(described_class.instance_variable_get(:@path)).to eq("/api/languages")
    end
  end

  describe ".list" do
    let(:client) { Octoprint::Client.new(host: "http://test.local", api_key: "test_key") }

    before do
      allow(described_class).to receive_messages(client: client)
      allow(described_class).to receive(:fetch_resource).and_return(
        described_class.new(language_packs: {})
      )
    end

    it "calls fetch_resource without parameters" do
      described_class.list

      expect(described_class).to have_received(:fetch_resource).with(no_args)
    end
  end

  describe ".upload" do
    let(:client) { Octoprint::Client.new(host: "http://test.local", api_key: "test_key") }
    let(:test_file) { "spec/files/test_language_pack.zip" }

    before do
      allow(described_class).to receive_messages(client: client, post: { language_packs: {} })
      allow(File).to receive(:exist?).with(test_file).and_return(true)
    end

    it "uploads a language pack without locale" do
      allow(Faraday::UploadIO).to receive(:new).and_return("mock_upload_io")

      result = described_class.upload(test_file)

      expect(Faraday::UploadIO).to have_received(:new).with(test_file, "application/octet-stream")
      expect(described_class).to have_received(:post).with(
        params: { file: "mock_upload_io" }
      )
      expect(result).to be_an(Array)
    end

    it "uploads a language pack with locale" do
      allow(Faraday::UploadIO).to receive(:new).and_return("mock_upload_io")

      result = described_class.upload(test_file, locale: "en")

      expect(described_class).to have_received(:post).with(
        params: { file: "mock_upload_io", locale: "en" }
      )
      expect(result).to be_an(Array)
    end
  end

  describe ".delete_pack" do
    let(:client) { Octoprint::Client.new(host: "http://test.local", api_key: "test_key") }

    before do
      allow(described_class).to receive_messages(client: client, delete: true)
    end

    it "constructs correct path for deletion" do
      described_class.delete_pack(locale: "en", pack: "plugin_test")

      expect(described_class).to have_received(:delete).with(
        path: "/api/languages/en/plugin_test"
      )
    end

    it "handles different locale and pack combinations" do
      described_class.delete_pack(locale: "de", pack: "core")

      expect(described_class).to have_received(:delete).with(
        path: "/api/languages/de/core"
      )
    end
  end

  describe Octoprint::Languages::LanguagePack do
    describe "#initialize" do
      it "creates a language pack with all attributes" do
        pack = described_class.new(
          identifier: "_core",
          display: "Core",
          languages: %w[en de]
        )

        expect(pack.identifier).to eq("_core")
        expect(pack.display).to eq("Core")
        expect(pack.languages).to eq(%w[en de])
      end
    end

    describe "deserialization" do
      it "includes Deserializable" do
        expect(described_class).to include(Octoprint::Deserializable)
      end

      it "includes AutoInitializable" do
        expect(described_class).to include(Octoprint::AutoInitializable)
      end

      it "deserializes from hash" do
        data = { identifier: "test", display: "Test", languages: ["en"] }
        pack = described_class.deserialize(data)

        expect(pack.identifier).to eq("test")
        expect(pack.display).to eq("Test")
        expect(pack.languages).to eq(["en"])
      end
    end
  end
end
