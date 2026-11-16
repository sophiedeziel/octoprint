# typed: true
# frozen_string_literal: true

module Octoprint
  class Files
    # Space used on a storage, in bytes
    #
    # @!attribute [r] free
    #   @return [Integer, nil] Free space
    # @!attribute [r] total
    #   @return [Integer, nil] Total space
    class Usage
      include AutoInitializable

      auto_attr :free, type: Integer
      auto_attr :total, type: Integer

      auto_initialize!
    end
  end
end
