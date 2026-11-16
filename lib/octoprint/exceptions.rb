# typed: strict
# frozen_string_literal: true

module Octoprint
  # Octoprint exceptions
  module Exceptions
    # Base error.
    class Error < StandardError; end
    # The client can't access the requested resources because of bad authentication
    class AuthenticationError < Error; end
    # The can't be processed because of invalid inputs
    class BadRequestError < Error; end
    # Credentials are missing from the configuration. Set them using `Octoprint.configure()`
    class MissingCredentialsError < Error; end
    # The server encountered an unexpected condition which prevented it from fulfilling the request
    class InternalServerError < Error; end
    # The server answered with an error status code the gem does not map to a specific error
    class UnknownError < Error; end
    # The request conflicts with the current state of the server (HTTP 409)
    class ConflictError < Error; end
    # The server refused the request body or file type (HTTP 415)
    class UnsupportedMediaTypeError < Error; end
    # The requested resource does not exist (HTTP 404)
    class NotFoundError < Error; end
    # The server could not be reached (connection refused, host unreachable, DNS failure, ...)
    class ConnectionError < Error; end
    # The server did not open the connection or respond within the configured timeouts
    class TimeoutError < ConnectionError; end
    # The feature needs a newer OctoPrint API than the client speaks. Raised before any request is sent.
    # See {Octoprint::Client#supports?} and the `api_version:` option of {Octoprint::Client#initialize}.
    class UnsupportedFeatureError < Error; end
  end
end
