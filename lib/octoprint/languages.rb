# typed: true
# frozen_string_literal: true

require "faraday"
require "faraday/multipart"

module Octoprint
  # Language packs available on the server
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

    # Represents a single language pack
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

    # Represents a list of language packs returned from upload
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
