# typed: true
# frozen_string_literal: true

module Octoprint
  class Slicing
    # A slicing profile of a slicer.
    #
    # Profiles returned in lists ({Slicing.list}, {Slicing.profiles}) don't include
    # the profile's {#data}. Use {Slicing.get_profile} to retrieve it.
    #
    # @example Read a profile
    #   profile = Octoprint::Slicing.get_profile(slicer: "curalegacy", key: "high_quality")
    #   profile.key          # => "high_quality"
    #   profile.display_name # => "High Quality"
    #   profile.default?     # => false
    #   profile.data         # => { layer_height: 0.1, ... }
    #
    # @see https://docs.octoprint.org/en/1.11.2/api/slicing.html#profile
    class Profile
      include Deserializable
      include AutoInitializable

      # @!attribute [r] key
      #   @return [String] The profile's identifier
      auto_attr :key, type: String, nilable: false

      # @!attribute [r] display_name
      #   @return [String, nil] The profile's human-readable name
      auto_attr :display_name, type: String

      # @!attribute [r] description
      #   @return [String, nil] The profile's description
      auto_attr :description, type: String

      # @!attribute [r] default
      #   @return [Boolean, nil] Whether this is the default profile of its slicer
      auto_attr :default, type: T::Boolean

      # @!attribute [r] resource
      #   @return [String, nil] The URL of the profile's API resource
      auto_attr :resource, type: String

      # @!attribute [r] data
      #   @return [Hash, nil] The slicer-specific profile settings. Only included by {Slicing.get_profile}
      auto_attr :data, type: Hash

      # @!attribute [r] extra
      #   @return [Hash, nil] Any additional fields returned by the API
      auto_attr :extra, type: Hash

      auto_initialize!

      # Whether this is the default profile of its slicer.
      #
      # @example
      #   Octoprint::Slicing.get_profile(slicer: "curalegacy", key: "high_quality").default? # => false
      #
      # @return [Boolean] false when {#default} is nil
      #: -> bool
      def default?
        default == true
      end
    end
  end
end
