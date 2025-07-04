# typed: true
# frozen_string_literal: true

require "faraday"
require "faraday/multipart"

module Octoprint
  # Information about files on the server
  #
  # Octoprint's API doc: https://docs.octoprint.org/en/master/api/files.html
  # rubocop:disable Metrics/ClassLength
  class Files < BaseResource
    extend T::Sig

    resource_path("/api/files")
    attr_reader :files, :free, :total

    def initialize(files:, free: nil, total: nil)
      @files = files.map { |file| Files::File.deserialize(file) }
      @free = free
      @total = total
      super()
    end

    # Fetches the list of files at a location
    #
    # @param [Location] location      The location to fetch the list of files from. Defaults to local.
    # @param [Hash] options           Additional parameters
    #
    # @return [Files]

    sig { params(location: Location, options: T::Hash[Symbol, T.untyped]).returns(Files) }
    def self.list(location: Location::Local, options: {})
      fetch_resource location.serialize, options: options
    end

    # Fetches a single file or folder
    #
    # @param [String] filename        The name of the file to fetch
    # @param [Location] location      The location to fetch the file from
    # @param [Hash] options           Additional parameters
    #
    # @return [Files::File]

    sig do
      params(filename: String, location: Location, options: T.nilable(T::Hash[Symbol, T.untyped])).returns(Files::File)
    end
    def self.get(filename:, location: Location::Local, options: {})
      path = [location.serialize, filename].compact.join("/")
      Files::File.deserialize(fetch_resource(path, deserialize: false, options: options))
    end

    # Uploads a file
    #
    # @param [String] file_path           The path to the file to upload.
    # @param [Location] location          The target location to which to upload the file.
    # @option options [String] :path      The path to upload the file to, relative to the location.
    # @option options [Boolean] :select   Whether to select the file directly after upload. Ignored when creating a
    #                                     folder.
    # @option options [Boolean] :print    Whether to start printing the file directly after upload. Ignored when
    #                                     creating a folder.
    # @option options [String] :userdata  An optional string that if specified will be interpreted as JSON and then
    #                                     saved along with the file as metadata (metadata key userdata). Ignored when
    #                                     creating a folder.
    # @return [OperationResult]

    sig do
      params(file_path: String, location: Location,
             options: {
               path: T.nilable(String),
               select: T.nilable(T::Boolean),
               print: T.nilable(T::Boolean),
               userdata: T.nilable(String)
             })
        .returns(OperationResult)
    end
    def self.upload(file_path, location: Location::Local, options: { path: nil, select: nil, print: nil,
                                                                     userdata: nil })
      params = {
        path: options[:path],
        select: options[:select],
        print: options[:print],
        userdata: options[:userdata],
        file: Faraday::UploadIO.new(file_path, "application/octet-stream")
      }.compact

      result = post(path: [@path, location.serialize].compact.join("/"), params: params)
      OperationResult.deserialize(result)
    end

    # Creates a folder
    #
    # @param [String] foldername      The name of the folder to create
    # @param [Location] location      The target location to which to upload the file.
    # @param [String] path            The path to create the folder in, relative to the location.
    # @param [Hash] kargs             Additional parameters
    #
    # @return [OperationResult]
    #
    # @example
    #           folder = Octoprint::Files.create_folder(foldername: "test")
    #           folder.name #=> "test"
    #           folder.origin #=> "local"
    #           folder.path #=> "test"
    #           folder.refs #=> {resource: "http://octoprint.local/api/files/local/test"}
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

      OperationResult.deserialize(result)
    end

    # Issues a file command
    #
    # @param [String] filename        The name of the file to issue the command to
    # @param [String] command         The command to issue (select, unselect, slice, copy, move)
    # @param [Location] location      The location of the file
    # @param [Hash] options           Additional command parameters
    # @option options [Boolean] :print    Whether to start printing after selection/slicing
    # @option options [String] :destination  Destination path for copy/move operations
    # @option options [Hash] :profile    Slicing profile for slice command
    #
    # @return [T.untyped] Response varies by command (204 No Content, 201 Created, or file data)
    sig do
      params(
        filename: String,
        command: String,
        location: Location,
        options: T::Hash[Symbol, T.untyped]
      )
        .returns(T.untyped)
    end
    def self.issue_command(filename:, command:, location: Location::Local, options: {})
      path = [@path, location.serialize, filename].compact.join("/")
      params = { command: command }.merge(options)
      post(path: path, params: params)
    end

    # Selects a file for printing
    #
    # @param [String] filename        The name of the file to select
    # @param [Location] location      The location of the file
    # @param [Boolean] print          Whether to start printing immediately after selection
    #
    # @return [T.untyped] 204 No Content on success
    sig do
      params(filename: String, location: Location, print: T.nilable(T::Boolean))
        .returns(T.untyped)
    end
    def self.select(filename:, location: Location::Local, print: nil)
      options = print.nil? ? {} : { print: print }
      issue_command(filename: filename, command: "select", location: location, options: options)
    end

    # Unselects the currently selected file
    #
    # @param [String] filename        The name of the file to unselect
    # @param [Location] location      The location of the file
    #
    # @return [T.untyped] 204 No Content on success
    sig do
      params(filename: String, location: Location)
        .returns(T.untyped)
    end
    def self.unselect(filename:, location: Location::Local)
      issue_command(filename: filename, command: "unselect", location: location, options: {})
    end

    # Slices an STL file into GCODE
    #
    # @param [String] filename        The name of the STL file to slice
    # @param [Location] location      The location of the file
    # @param [Boolean] print          Whether to start printing after slicing
    # @param [Hash] profile           Slicing profile settings
    #
    # @return [T.untyped] 202 Accepted with file information
    sig do
      params(
        filename: String,
        location: Location,
        print: T.nilable(T::Boolean),
        profile: T.nilable(T::Hash[Symbol, T.untyped])
      )
        .returns(T.untyped)
    end
    def self.slice(filename:, location: Location::Local, print: nil, profile: nil)
      options = {}
      options[:print] = print unless print.nil?
      options.merge!(profile) if profile
      issue_command(filename: filename, command: "slice", location: location, options: options)
    end

    # Copies a file or folder
    #
    # @param [String] filename        The name of the file or folder to copy
    # @param [String] destination     The destination path for the copy
    # @param [Location] location      The location of the source file
    #
    # @return [T.untyped] 201 Created with file information
    sig do
      params(filename: String, destination: String, location: Location)
        .returns(T.untyped)
    end
    def self.copy(filename:, destination:, location: Location::Local)
      issue_command(filename: filename, command: "copy", location: location, options: { destination: destination })
    end

    # Moves a file or folder
    #
    # @param [String] filename        The name of the file or folder to move
    # @param [String] destination     The destination path for the move
    # @param [Location] location      The location of the source file
    #
    # @return [T.untyped] 201 Created with file information
    sig do
      params(filename: String, destination: String, location: Location)
        .returns(T.untyped)
    end
    def self.move(filename:, destination:, location: Location::Local)
      issue_command(filename: filename, command: "move", location: location, options: { destination: destination })
    end

    # Deletes a file
    #
    # @param [String] filename        The name of the file to delete
    # @param [Location] location      The location of the file
    #
    # @return [T.untyped] 204 No Content on success
    sig do
      params(filename: String, location: Location)
        .returns(T.untyped)
    end
    def self.delete_file(filename:, location: Location::Local)
      path = [@path, location.serialize, filename].compact.join("/")
      delete(path: path)
    end
  end
  # rubocop:enable Metrics/ClassLength
end
