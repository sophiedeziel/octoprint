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
    class UnknownError < Error; end
    class ConflictError < Error; end
    class UnsupportedMediaTypeError < Error; end
    class NotFoundError < Error; end
  end
end
