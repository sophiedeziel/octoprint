# typed: true
# frozen_string_literal: true

module Octoprint
  # Language pack management for OctoPrint server internationalization
  #
  # This class provides methods to manage language packs on the OctoPrint server.
  # Language packs enable OctoPrint's user interface to be displayed in different
  # languages. The API supports listing installed packs, uploading new language
  # pack archives, and removing existing language packs.
  #
  # Language packs are organized by identifier (e.g., "_core", plugin names) and
  # contain translations for specific locales (e.g., "fr", "de", "es").
  #
  # @example List all available language packs
  #   languages = Octoprint::Languages.list
  #   languages.language_packs.each do |pack_id, pack|
  #     puts "#{pack.display}: #{pack.languages.join(', ')}"
  #   end
  #
  # @example Upload a new language pack
  #   result = Octoprint::Languages.upload("path/to/language-pack.zip")
  #   puts "Uploaded #{result.length} language packs"
  #   result.each do |pack|
  #     puts "- #{pack.display} (#{pack.identifier}): #{pack.languages.join(', ')}"
  #   end
  #
  # @example Upload with specific locale
  #   result = Octoprint::Languages.upload("french.zip", locale: "fr")
  #   puts "Installed French translations for #{result.length} components"
  #
  # @example Remove a language pack
  #   Octoprint::Languages.delete_pack(locale: "fr", pack: "_core")
  #
  # Octoprint's API doc: https://docs.octoprint.org/en/1.11.2/api/languages.html
  class Languages < BaseResource
    extend T::Sig
    include AutoInitializable
    include Deserializable

    resource_path("/api/languages")

    auto_attr :language_packs, type: Hash, nilable: false
    auto_attr :extra, type: Hash

    auto_initialize!

    deserialize_config do
      transform do |data|
        # Transform the hash of pack_id => pack_info into proper objects
        if data[:language_packs].is_a?(Hash)
          data[:language_packs] = data[:language_packs].transform_values do |pack_info|
            LanguagePack.deserialize(pack_info)
          end
        end
      end
      collect_extras
    end

    # Fetches the list of available language packs
    #
    # @return [Languages]
    sig { returns(Languages) }
    def self.list
      fetch_resource
    end

    # Uploads a language pack
    #
    # @param [String] file_path     The path to the language pack archive to upload
    # @param [String] locale        Optional. If provided, forces the locale the pack will be installed under
    #
    # @return [Array<LanguagePack>] List of installed language packs
    sig do
      params(file_path: String, locale: T.nilable(String))
        .returns(T::Array[LanguagePack])
    end
    def self.upload(file_path, locale: nil)
      params = {
        file: Faraday::UploadIO.new(file_path, "application/octet-stream")
      }
      params[:locale] = locale if locale

      result = post(params: params)
      # Handle nested hash structure: {language_packs: {pack_id: pack_info}}
      result[:language_packs].values.map { |pack| LanguagePack.deserialize(pack) }
    end

    # Deletes a language pack
    #
    # @param [String] locale    The locale of the pack to delete
    # @param [String] pack      The identifier of the pack to delete
    #
    # @return [T.untyped] 204 No Content on success
    sig do
      params(locale: String, pack: String)
        .returns(T.untyped)
    end
    def self.delete_pack(locale:, pack:)
      path = [@path, locale, pack].compact.join("/")
      delete(path: path)
    end
  end
end
