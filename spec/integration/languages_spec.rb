# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Languages, type: :integration do
  include_context "with default Octoprint config"

  describe "Get language packs list", vcr: { cassette_name: "languages/list" } do
    use_octoprint_server

    subject(:language_list) { described_class.list }

    it { is_expected.to be_a described_class }
    its(:language_packs) { is_expected.to be_a Hash }
    its(:language_packs) { is_expected.not_to be_empty }

    it "contains language pack objects with proper structure" do
      expect(language_list.language_packs).to all(
        satisfy do |pack_id, pack|
          pack_id.is_a?(Symbol) && pack.is_a?(Octoprint::Languages::LanguagePack)
        end
      )
    end

    it "language packs have proper attributes" do
      language_list.language_packs.each_value do |pack|
        expect(pack.identifier).to be_a(String)
        expect(pack.display).to be_a(String)
        expect(pack.languages).to be_an(Array)
      end
    end
  end

  describe "Upload a language pack", vcr: { cassette_name: "languages/upload" } do
    use_octoprint_server

    subject(:upload) { described_class.upload(file_path, **params) }

    let(:file_path) { "spec/files/french_language_pack.zip" }
    let(:params) { {} }

    it { is_expected.to be_an Array }

    it "contains LanguagePack objects" do
      expect(upload).to all(be_a(Octoprint::Languages::LanguagePack))
    end

    context "when specifying a locale", vcr: { cassette_name: "languages/upload_with_locale" } do
      let(:params) { { locale: "en" } }

      it { is_expected.to be_an Array }
    end

    context "when upload fails due to invalid file", vcr: { cassette_name: "languages/upload_invalid" } do
      let(:file_path) { "spec/files/invalid.txt" }

      before do
        File.write(file_path, "not a valid language pack")
      end

      it "raises an appropriate error" do
        expect { upload }.to raise_error(Octoprint::Exceptions::BadRequestError)
      end
    end
  end

  describe "Delete a language pack", vcr: { cassette_name: "languages/delete" } do
    use_octoprint_server

    subject(:delete) { described_class.delete_pack(locale: locale, pack: pack) }

    let(:locale) { "fr" }
    let(:pack) { "_core" }

    context "when the pack exists" do
      it "returns success (204 No Content)" do
        expect(delete).to be_truthy
      end
    end

    context "when the pack does not exist", vcr: { cassette_name: "languages/delete_not_found" } do
      let(:locale) { "fr" }
      let(:pack) { "nonexistent_pack" }

      it "returns successfully (API doesn't return errors for non-existent packs)" do
        expect(delete).to be_truthy
      end
    end

    context "when trying to delete a core pack", vcr: { cassette_name: "languages/delete_core" } do
      let(:locale) { "fr" }
      let(:pack) { "core" }

      it "returns successfully (API doesn't return conflict errors)" do
        expect(delete).to be_truthy
      end
    end
  end
end
