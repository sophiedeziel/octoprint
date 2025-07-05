# typed: true
# frozen_string_literal: true

module Octoprint
  class Languages
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
