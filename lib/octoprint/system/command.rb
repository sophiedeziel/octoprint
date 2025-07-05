# typed: strict
# frozen_string_literal: true

module Octoprint
  class System
    # Represents a single system command available on the OctoPrint server.
    # System commands can be used to perform actions like shutdown, restart, etc.
    #
    # @see https://docs.octoprint.org/en/master/api/system.html#data-model
    class Command
      extend T::Sig
      include Deserializable
      include AutoInitializable

      # @!attribute [r] action
      #   @return [String] The unique identifier/action name for this command
      auto_attr :action, type: String, nilable: false

      # @!attribute [r] name
      #   @return [String] The human-readable name of the command
      auto_attr :name, type: String, nilable: false

      # @!attribute [r] confirm
      #   @return [String, nil] Optional confirmation message to show before executing
      auto_attr :confirm, type: String

      # @!attribute [r] source
      #   @return [String] The source of the command (e.g., "core" or "custom")
      auto_attr :source, type: String, nilable: false

      # @!attribute [r] resource
      #   @return [String] The URL endpoint for executing this command
      auto_attr :resource, type: String, nilable: false

      # @!attribute [r] extra
      #   @return [Hash] Any additional fields returned by the API that are not explicitly defined
      auto_attr :extra, type: Hash

      auto_initialize!
    end
  end
end
