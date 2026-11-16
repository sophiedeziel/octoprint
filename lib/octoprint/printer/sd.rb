# typed: true
# frozen_string_literal: true

module Octoprint
  class Printer
    # The printer's SD card: state and commands.
    #
    # Requires the +CONTROL+ permission for commands and +STATUS+ for {.get}.
    #
    # @example Check whether the SD card is ready
    #   Octoprint::Printer::Sd.get.ready # => true
    #
    # @example Initialize, refresh and release the SD card
    #   Octoprint::Printer::Sd.init
    #   Octoprint::Printer::Sd.refresh
    #   Octoprint::Printer::Sd.release
    #
    # @see https://docs.octoprint.org/en/master/api/printer.html#issue-an-sd-command
    class Sd < BaseResource
      include AutoInitializable
      include Deserializable

      resource_path("/api/printer/sd")

      # @!attribute [r] ready
      #   @return [Boolean] Whether the SD card has been initialized
      auto_attr :ready, type: Types::Boolean

      # @!attribute [r] extra
      #   @return [Hash, nil] Any additional fields returned by the API
      auto_attr :extra, type: Hash

      auto_initialize!

      # Retrieves the current state of the printer's SD card.
      #
      # @example
      #   Octoprint::Printer::Sd.get.ready # => true
      #
      # @return [Printer::Sd] The SD card state
      # @raise [Octoprint::Exceptions::NotFoundError] if SD support is disabled in OctoPrint's settings
      #: -> Sd
      def self.get
        fetch_resource
      end

      # Issues an SD command.
      #
      # @param command [String] The command to issue: +init+, +refresh+ or +release+
      #
      # @example
      #   Octoprint::Printer::Sd.issue_command(command: "refresh")
      #
      # @return [Boolean] true on success (204 No Content)
      # @raise [Octoprint::Exceptions::ConflictError] if the card isn't initialized (+refresh+ and +release+)
      #: (command: String) -> untyped
      def self.issue_command(command:)
        post(params: { command: command })
      end

      # Initializes the printer's SD card and retrieves its file list.
      #
      # @example
      #   Octoprint::Printer::Sd.init
      #
      # @return [Boolean] true on success (204 No Content)
      #: -> untyped
      def self.init
        issue_command(command: "init")
      end

      # Refreshes the list of files stored on the printer's SD card.
      #
      # @example
      #   Octoprint::Printer::Sd.refresh
      #
      # @return [Boolean] true on success (204 No Content)
      # @raise [Octoprint::Exceptions::ConflictError] if the card hasn't been initialized
      #: -> untyped
      def self.refresh
        issue_command(command: "refresh")
      end

      # Releases the SD card from the printer. The reverse operation of {.init}.
      #
      # @example
      #   Octoprint::Printer::Sd.release
      #
      # @return [Boolean] true on success (204 No Content)
      # @raise [Octoprint::Exceptions::ConflictError] if the card hasn't been initialized
      #: -> untyped
      def self.release
        issue_command(command: "release")
      end
    end
  end
end
