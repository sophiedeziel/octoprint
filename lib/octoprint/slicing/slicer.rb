# typed: true
# frozen_string_literal: true

module Octoprint
  class Slicing
    # A slicer registered on the OctoPrint server, with its slicing profiles.
    #
    # @example Inspect a slicer
    #   slicer = Octoprint::Slicing.list[:curalegacy]
    #   slicer.key          # => "curalegacy"
    #   slicer.display_name # => "CuraEngine Legacy"
    #   slicer.configured?  # => true
    #   slicer.profiles.keys # => [:high_quality, :normal_quality]
    #
    # @see https://docs.octoprint.org/en/1.11.2/api/slicing.html#slicer
    class Slicer
      extend T::Sig
      include Deserializable
      include AutoInitializable

      # @!attribute [r] key
      #   @return [String] The slicer's identifier
      auto_attr :key, type: String, nilable: false

      # @!attribute [r] display_name
      #   @return [String, nil] The slicer's human-readable name
      auto_attr :display_name, type: String

      # @!attribute [r] default
      #   @return [Boolean, nil] Whether this is the default slicer
      auto_attr :default, type: T::Boolean

      # @!attribute [r] configured
      #   @return [Boolean, nil] Whether the slicer is configured and ready to slice
      auto_attr :configured, type: T::Boolean

      # @!attribute [r] same_device
      #   @return [Boolean, nil] Whether the slicer runs on the same device as OctoPrint
      auto_attr :same_device, type: T::Boolean

      # @!attribute [r] extensions
      #   @return [Hash, nil] The file extensions the slicer accepts (+:source+) and produces (+:destination+)
      auto_attr :extensions, type: Hash

      # @!attribute [r] profiles
      #   @return [Hash{Symbol => Profile}] The slicer's profiles, by key. Profiles don't include their data
      auto_attr :profiles, type: Hash, nilable: false

      # @!attribute [r] extra
      #   @return [Hash, nil] Any additional fields returned by the API
      auto_attr :extra, type: Hash

      auto_initialize!

      deserialize_config do
        transform do |data|
          data[:profiles] = Slicing.deserialize_profiles(data[:profiles])
        end
      end

      # Whether this is the default slicer.
      #
      # @example
      #   Octoprint::Slicing.list[:curalegacy].default? # => true
      #
      # @return [Boolean] false when {#default} is nil
      sig { returns(T::Boolean) }
      def default?
        default == true
      end

      # Whether the slicer is configured and ready to slice.
      #
      # @example
      #   Octoprint::Slicing.list[:curalegacy].configured? # => false
      #
      # @return [Boolean] false when {#configured} is nil
      sig { returns(T::Boolean) }
      def configured?
        configured == true
      end
    end
  end
end
