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
  #   puts "Uploaded #{result.language_packs.length} language packs"
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
    # @return [LanguagePackList] List of installed language packs
    sig do
      params(file_path: String, locale: T.nilable(String))
        .returns(LanguagePackList)
    end
    def self.upload(file_path, locale: nil)
      params = {
        file: Faraday::UploadIO.new(file_path, "application/octet-stream")
      }
      params[:locale] = locale if locale

      result = post(params: params)
      LanguagePackList.deserialize(result)
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

    # Represents a single language pack available on the server
    #
    # A language pack contains translations for a specific component (like the core
    # OctoPrint interface or a plugin) and includes information about which locales
    # are available within that pack.
    #
    # @example Access language pack information
    #   pack = languages.language_packs["_core"]
    #   puts pack.display           # => "Core"
    #   puts pack.identifier        # => "_core"
    #   puts pack.languages         # => ["fr", "de", "es"]
    class LanguagePack
      extend T::Sig
      include Deserializable
      include AutoInitializable

      auto_attr :identifier, type: String, nilable: false
      auto_attr :display, type: String, nilable: false
      auto_attr :languages, type: Array, nilable: false
      auto_attr :extra, type: Hash

      auto_initialize!

      deserialize_config do
        collect_extras
      end
    end

    # Represents the response from uploading language pack archives
    #
    # When language packs are uploaded to the server, this class contains
    # the list of language pack objects that were successfully installed.
    # This allows you to see what translations are now available after
    # an upload operation.
    #
    # @example Check upload results
    #   result = Octoprint::Languages.upload("my-translation.zip")
    #   result.language_packs.each do |pack|
    #     puts "Installed: #{pack.display} (#{pack.identifier})"
    #   end
    class LanguagePackList
      extend T::Sig
      include Deserializable
      include AutoInitializable

      auto_attr :language_packs, type: LanguagePack, array: true, nilable: false
      auto_attr :extra, type: Hash

      auto_initialize!

      deserialize_config do
        array :language_packs, LanguagePack
        collect_extras
      end
    end
  end
end
