# typed: true
# frozen_string_literal: true

module Octoprint
  class Printer
    # Information about the last error reported by the printer.
    #
    # Requires the +STATUS+ permission. The {#logs} are only included when the user
    # also has the +MONITOR_TERMINAL+ permission.
    #
    # When no error has occurred, the server still returns +error+ and +reason+, as
    # empty strings, and leaves out +consequence+, +faq+ and +logs+. Use {#error?} to
    # check whether there is an error.
    #
    # @example Check for an error
    #   info = Octoprint::Printer::ErrorInformation.get
    #   info.error? # => false
    #   info.error  # => ""
    #
    # @example Inspect the last firmware error
    #   info = Octoprint::Printer.last_error
    #   info.error       # => "MINTEMP triggered!"
    #   info.reason      # => "firmware"
    #   info.consequence # => "emergency"
    #   info.faq_url     # => "https://faq.octoprint.org/firmware-mintemp"
    #   info.logs        # => ["Recv: Error:MINTEMP triggered!", ...]
    #
    # @see https://docs.octoprint.org/en/1.11.8/api/printer.html#retrieve-information-about-the-last-error
    class ErrorInformation < BaseResource
      include AutoInitializable
      include Deserializable

      resource_path("/api/printer/error")

      # Base URL of OctoPrint's FAQ, completed with {#faq} to build {#faq_url}.
      FAQ_BASE_URL = "https://faq.octoprint.org/"

      # @!attribute [r] error
      #   @return [String, nil] The error message, empty when there is no error
      auto_attr :error, type: String

      # @!attribute [r] reason
      #   @return [String, nil] The reason for the error, for example +firmware+. Empty when there is no error
      auto_attr :reason, type: String

      # @!attribute [r] consequence
      #   @return [String, nil] What the error triggered: +emergency+, +disconnect+ or +cancel+.
      #     nil when nothing was triggered or there is no error
      auto_attr :consequence, type: String

      # @!attribute [r] faq
      #   @return [String, nil] The id of the matching FAQ entry, nil when there is none or no error.
      #     See {#faq_url}
      auto_attr :faq, type: String

      # @!attribute [r] logs
      #   @return [Array<String>, nil] Terminal lines related to the error. nil when there is no error
      #     or the user lacks the +MONITOR_TERMINAL+ permission
      auto_attr :logs, type: String, array: true

      # @!attribute [r] extra
      #   @return [Hash, nil] Any additional fields returned by the API
      auto_attr :extra, type: Hash

      auto_initialize!

      # Retrieves information about the last error reported by the printer.
      #
      # @example
      #   Octoprint::Printer::ErrorInformation.get.error # => "MINTEMP triggered!"
      #
      # @return [Printer::ErrorInformation] The last error information
      # @raise [Octoprint::Exceptions::AuthenticationError] if the user lacks the +STATUS+ permission
      #: -> ErrorInformation
      def self.get
        fetch_resource
      end

      # Whether the server reported an error.
      #
      # @example
      #   Octoprint::Printer.last_error.error? # => false
      #
      # @return [Boolean] false when {#error} is nil or empty
      #: -> bool
      def error?
        !error.to_s.empty?
      end

      # The link to the FAQ entry for this error.
      #
      # @example
      #   Octoprint::Printer.last_error.faq_url # => "https://faq.octoprint.org/firmware-mintemp"
      #
      # @return [String, nil] The FAQ URL, nil when there is no FAQ entry
      #: -> String?
      def faq_url
        return if faq.to_s.empty?

        "#{FAQ_BASE_URL}#{faq}"
      end
    end
  end
end
