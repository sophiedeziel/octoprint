# typed: true
# frozen_string_literal: true

module Octoprint
  # Represents a user from the OctoPrint API
  class User
    include Deserializable
    include AutoInitializable

    # Basic user attributes
    auto_attr :name, type: String, nilable: false
    auto_attr :permissions, type: Array
    auto_attr :groups, type: Array
    auto_attr :extra, type: Hash

    auto_initialize!

    deserialize_config do
      # Collect any unknown fields for future compatibility
      collect_extras
    end
  end
end
