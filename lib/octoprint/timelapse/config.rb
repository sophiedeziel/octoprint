# typed: true
# frozen_string_literal: true

module Octoprint
  class Timelapse
    # The timelapse configuration used for the next print.
    #
    # Which attributes are set depends on {#type}: +off+ has none, +zchange+ has
    # {#retraction_z_hop} and {#min_delay}, and +timed+ has {#interval}.
    #
    # @example
    #   config = Octoprint::Timelapse.get.config
    #   config.type     # => "timed"
    #   config.interval # => 10
    #   config.fps      # => 25
    #
    # @see https://docs.octoprint.org/en/1.11.2/api/timelapse.html#timelapse-configuration
    class Config
      include AutoInitializable
      include Deserializable

      # @!attribute [r] type
      #   @return [String] +off+, +zchange+ or +timed+
      auto_attr :type, type: String

      # @!attribute [r] post_roll
      #   @return [Integer, nil] Post roll in seconds
      auto_attr :post_roll, type: Integer

      # @!attribute [r] fps
      #   @return [Integer, nil] Frames per second of the rendered video
      auto_attr :fps, type: Integer

      # @!attribute [r] render_after_print
      #   @return [String, nil] When to render after the print: +always+, +success+, +failure+ or +never+
      auto_attr :render_after_print, type: String

      # @!attribute [r] interval
      #   @return [Integer, nil] Seconds between snapshots (+timed+ only)
      auto_attr :interval, type: Integer

      # @!attribute [r] retraction_z_hop
      #   @return [Numeric, nil] Retraction Z hop ignored when detecting Z changes (+zchange+ only)
      auto_attr :retraction_z_hop, type: Numeric

      # @!attribute [r] min_delay
      #   @return [Numeric, nil] Minimum seconds between snapshots (+zchange+ only)
      auto_attr :min_delay, type: Numeric

      # @!attribute [r] extra
      #   @return [Hash, nil] Any additional fields returned by the API
      auto_attr :extra, type: Hash

      auto_initialize!

      # Whether timelapses are turned off for the next print
      #
      # @example
      #   Octoprint::Timelapse.get.config.off? # => true
      #
      # @return [Boolean]
      #: -> bool
      def off?
        type == "off"
      end
    end
  end
end
