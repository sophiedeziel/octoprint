# frozen_string_literal: true

require "faraday"
require "faraday/multipart"

module Octoprint
  # Information about files on the server
  #
  # Octoprint's API doc: https://docs.octoprint.org/en/master/api/files.html
  class Files < BaseResource
    resource_path("/api/files")
    attr_reader :files, :free, :total

    def initialize(files:, free: nil, total: nil)
      @files = files
      @free = free
      @total = total
      super()
    end

    def self.list(location: :local)
      fetch_resource location
    end

    def self.upload(file_path, location: :local, **kargs)
      params = {
        path: kargs[:path],
        select: kargs[:select],
        print: kargs[:print],
        userdata: kargs[:userdata],
        file: Faraday::UploadIO.new(file_path, "application/octet-stream")
      }.compact

      headers = { "Content-Type" => "multipart/form-data" }

      post(path: [@path, location].compact.join("/"), params: params, headers: headers)
    end
  end
end
