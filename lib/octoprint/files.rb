# frozen_string_literal: true

module Octoprint
  # Information about files on the server
  #
  # Octoprint's API doc: https://docs.octoprint.org/en/master/api/files.html
  class Files < BaseResource
    resource_path("/api/files")
    attr_reader :files, :free, :total

    def initialize(files:, free:, total:)
      @files = files
      @free = free
      @total = total
      super()
    end

    def self.list
      fetch_resource
    end
  end
end
