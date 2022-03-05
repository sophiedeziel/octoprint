# frozen_string_literal: true

module Octoprint
  # Octoprint exceptions
  module Exceptions
    # Base error.
    class Error < StandardError; end
    # The client can't access the requested resources because of bad authentication
    class AuthenticationError < Error; end
    # Credentials are missing from the configuration. Set them using `Octoprint.configure()`
    class MissingCredentials < Error; end
  end
end
