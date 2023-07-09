# typed: true
# frozen_string_literal: true

require "faraday"
require "faraday/multipart"

module Octoprint
  # Information about files on the server
  #
  # Octoprint's API doc: https://docs.octoprint.org/en/master/api/files.html
  class Files < BaseResource
    extend T::Sig

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

      post(path: [@path, location].compact.join("/"), params: params)
    end

    # Creates a folder
    #
    # @param [String] foldername      The name of the folder to create
    # @param [Location] location      The target location to which to upload the file.
    # @param [String] path            The path to create the folder in, relative to the location.
    # @param [Hash] kargs             Additional parameters
    # @return [Files::Folder]
    #
    # @example
    #           folder = Octoprint::Files.create_folder(foldername: "test")
    #           folder.name #=> "test"
    #           folder.origin #=> "local"
    #           folder.path #=> "test"
    #           folder.refs #=> {resource: "http://localhost:5000/api/files/local/test"}
    sig do
      params(
        foldername: String,
        location: Location,
        path: T.nilable(String),
        _kargs: T::Hash[Symbol, T.untyped]
      )
        .returns(OperationResult)
    end
    def self.create_folder(foldername:, location: Location::Local, path: nil, **_kargs)
      params = {
        path: path,
        foldername: foldername
      }.compact

      result = post(path: [@path, location.serialize].compact.join("/"), params: params,
                    options: { force_multipart: true })
      OperationResult.new(done: result[:done], folder: Folder.new(**result[:folder]))
    end
  end
end
