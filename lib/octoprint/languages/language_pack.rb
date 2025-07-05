# typed: true
# frozen_string_literal: true

module Octoprint
  class Languages
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
  end
end
