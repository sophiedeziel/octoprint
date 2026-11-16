# typed: true
# frozen_string_literal: true

module Octoprint
  class Printer
    # The printer's own storage (usually its SD card): state and commands.
    #
    # OctoPrint 2.0 renamed the SD card API to printer storage (`/api/printer/storage`). This resource works with
    # both API versions: with the 1.x API it calls `/api/printer/sd`, which takes the same commands and returns the
    # same state.
    #
    # Requires the +CONTROL+ permission for commands and +STATUS+ for {.get}.
    #
    # @example Check whether the printer's storage is ready
    #   Octoprint::Printer::Storage.get.ready # => true
    #
    # @example Initialize, refresh and release the printer's storage
    #   Octoprint::Printer::Storage.init
    #   Octoprint::Printer::Storage.refresh
    #   Octoprint::Printer::Storage.release
    #
    # @see https://docs.octoprint.org/en/dev/api/printer.html OctoPrint 2.0 Printer API Documentation
    # @see https://docs.octoprint.org/en/master/api/printer.html#issue-an-sd-command OctoPrint 1.x SD commands
    class Storage < BaseResource
      include AutoInitializable
      include Deserializable

      resource_path("/api/printer/storage")

      # @!attribute [r] ready
      #   @return [Boolean] Whether the printer's storage has been initialized
      auto_attr :ready, type: Types::Boolean

      # @!attribute [r] extra
      #   @return [Hash, nil] Any additional fields returned by the API
      auto_attr :extra, type: Hash

      auto_initialize!

      # Retrieves the current state of the printer's storage.
      #
      # @example
      #   Octoprint::Printer::Storage.get.ready # => true
      #
      # @return [Printer::Storage] The storage state
      # @raise [Octoprint::Exceptions::NotFoundError] if SD support is disabled in OctoPrint's settings
      #: -> Storage
      def self.get
        fetch_resource
      end

      # Issues a storage command.
      #
      # @param command [String] The command to issue: +init+, +refresh+ or +release+
      #
      # @example
      #   Octoprint::Printer::Storage.issue_command(command: "refresh")
      #
      # @return [Boolean] true on success (204 No Content)
      # @raise [Octoprint::Exceptions::ConflictError] if the printer isn't operational or is busy
      # @raise [Octoprint::Exceptions::BadRequestError] if the command is unknown
      #: (command: String) -> untyped
      def self.issue_command(command:)
        post(params: { command: command })
      end

      # Initializes the printer's storage and retrieves its file list.
      #
      # @example
      #   Octoprint::Printer::Storage.init
      #
      # @return [Boolean] true on success (204 No Content)
      # @raise [Octoprint::Exceptions::ConflictError] if the printer isn't operational or is busy
      #: -> untyped
      def self.init
        issue_command(command: "init")
      end

      # Refreshes the list of files stored on the printer's storage.
      #
      # @example
      #   Octoprint::Printer::Storage.refresh
      #
      # @return [Boolean] true on success (204 No Content)
      # @raise [Octoprint::Exceptions::ConflictError] if the printer isn't operational or is busy
      #: -> untyped
      def self.refresh
        issue_command(command: "refresh")
      end

      # Releases the printer's storage. The reverse operation of {.init}.
      #
      # @example
      #   Octoprint::Printer::Storage.release
      #
      # @return [Boolean] true on success (204 No Content)
      # @raise [Octoprint::Exceptions::ConflictError] if the printer isn't operational or is busy
      #: -> untyped
      def self.release
        issue_command(command: "release")
      end
    end
  end
end
