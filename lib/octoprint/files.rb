# typed: true
# frozen_string_literal: true

require "faraday"
require "faraday/multipart"

module Octoprint
  # The files on one storage of the server, and the Files API
  #
  # The model follows the OctoPrint 2.0 shape of a storage (`GET /api/files/<storage>`). With the 1.x API, the
  # responses are converted by {Files::Legacy}: `key` is filled in, `usage` comes from `free`/`total`, and `name` and
  # `capabilities` are nil (1.x doesn't report them).
  #
  # @example List the files on the local storage
  #   files = Octoprint::Files.list
  #   files.key            # => "local"
  #   files.usage.free     # => 491531599872
  #   files.files.first    # => #<Octoprint::Files::File ...>
  #
  # @example List every storage at once
  #   Octoprint::Files.list_all.keys # => [:local, :printer]
  #
  # Octoprint's API doc: https://docs.octoprint.org/en/master/api/files.html
  class Files < BaseResource
    resource_path("/api/files")

    # @return [Array<Files::File>] The files and folders on the storage
    #: Array[Files::File]
    attr_reader :files

    # @return [String, nil] The storage's key, e.g. `"local"` or `"printer"`
    #: String?
    attr_reader :key

    # @return [String, nil] The storage's display name, e.g. `"Local"`. nil with the 1.x API
    #: String?
    attr_reader :name

    # @return [Hash{Symbol => Boolean}, nil] What the storage supports, e.g. `{ add_folder: true, thumbnails: true }`.
    #   nil with the 1.x API
    #: Hash[Symbol, bool]?
    attr_reader :capabilities

    # @return [Files::Usage, nil] Free and total space. nil when the storage doesn't report it (e.g. the printer)
    #: Files::Usage?
    attr_reader :usage

    # @param files [Array<Hash>] The files and folders on the storage
    # @param key [String, nil] The storage's key
    # @param name [String, nil] The storage's display name
    # @param capabilities [Hash{Symbol => Boolean}, nil] What the storage supports
    # @param usage [Hash, Files::Usage, nil] Free and total space
    # @param free [Integer, nil] Free space, for the 1.x shape. Ignored when `usage` is given
    # @param total [Integer, nil] Total space, for the 1.x shape. Ignored when `usage` is given
    #: (
    #|   files: Array[Hash[Symbol, untyped]],
    #|   ?key: String?,
    #|   ?name: String?,
    #|   ?capabilities: Hash[Symbol, bool]?,
    #|   ?usage: (Hash[Symbol, untyped] | Files::Usage)?,
    #|   ?free: Integer?,
    #|   ?total: Integer?,
    #|   **untyped
    #| ) -> void
    def initialize(files:, key: nil, name: nil, capabilities: nil, usage: nil, free: nil, total: nil, **_extra)
      @files = files.map { |file| Files::File.deserialize(file) }
      @key = key
      @name = name
      @capabilities = capabilities
      usage ||= { free: free, total: total } unless free.nil? && total.nil?
      @usage = usage.is_a?(Hash) ? Files::Usage.new(**usage) : usage
      super()
    end

    # @return [Integer, nil] Free space on the storage, in bytes. Shortcut for `usage.free`
    #: -> Integer?
    def free
      usage&.free
    end

    # @return [Integer, nil] Total space on the storage, in bytes. Shortcut for `usage.total`
    #: -> Integer?
    def total
      usage&.total
    end

    # Fetches the list of files at a location
    #
    # @example
    #   Octoprint::Files.list(location: Octoprint::Location::Printer, options: { recursive: true })
    #
    # @param [Location] location      The location to fetch the list of files from. Defaults to local.
    # @param [Hash] options           Additional parameters (`filter`, `recursive`, `force`)
    #
    # @return [Files]
    #: (?location: Location, ?options: Hash[Symbol, untyped]) -> Files
    def self.list(location: Location::Local, options: {})
      fetch_resource location.serialize, options: options
    end

    # Fetches the files of every storage (`GET /api/files`)
    #
    # With the 1.x API, the single 1.x list is split by origin: `:local` is always there, `:printer` only when the
    # printer has files.
    #
    # @example
    #   storages = Octoprint::Files.list_all(options: { recursive: true })
    #   storages[:local].files     # => [#<Octoprint::Files::File ...>]
    #   storages[:printer]&.files  # => nil when no printer is connected
    #
    # @param [Hash] options           Additional parameters (`filter`, `recursive`, `force`)
    # @return [Hash{Symbol => Files}] The storages, by key (`:local`, `:printer`)
    #: (?options: Hash[Symbol, untyped]) -> Hash[Symbol, Files]
    def self.list_all(options: {})
      storages = fetch_resource(nil, deserialize: false, options: options)
      storages.transform_values { |storage| deserialize(storage) }
    end

    # Fetches a single file or folder
    #
    # @param [String] filename        The name of the file to fetch
    # @param [Location] location      The location to fetch the file from
    # @param [Hash] options           Additional parameters
    #
    # @return [Files::File]
    #: (
    #|   filename: String,
    #|   ?location: Location,
    #|   ?options: Hash[Symbol, untyped]?
    #| ) -> Files::File
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
    # @return [OperationResult] The uploaded file is in `file`
    #
    # @example
    #   result = Octoprint::Files.upload("benchy.gcode", options: { select: true })
    #   result.file.path        # => "benchy.gcode"
    #   result.effective_select # => true
    #: (
    #|   String file_path,
    #|   ?location: Location,
    #|   ?options: {path: String?, select: bool?, print: bool?, userdata: String?}
    #| ) -> OperationResult
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
    #: (
    #|   foldername: String,
    #|   ?location: Location,
    #|   ?path: String?,
    #|   **Hash[Symbol, untyped] _kargs
    #| ) -> OperationResult
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
    #: (
    #|   filename: String,
    #|   command: String,
    #|   ?location: Location,
    #|   ?options: Hash[Symbol, untyped]
    #| ) -> untyped
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
    #: (
    #|   filename: String,
    #|   ?location: Location,
    #|   ?print: bool?
    #| ) -> untyped
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
    #: (
    #|   filename: String,
    #|   ?location: Location
    #| ) -> untyped
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
    #: (
    #|   filename: String,
    #|   ?location: Location,
    #|   ?print: bool?,
    #|   ?profile: Hash[Symbol, untyped]?
    #| ) -> untyped
    def self.slice(filename:, location: Location::Local, print: nil, profile: nil)
      options = {}
      options[:print] = print unless print.nil?
      options.merge!(profile) if profile
      issue_command(filename: filename, command: "slice", location: location, options: options)
    end

    # Copies a file or folder
    #
    # @example Copy within the local storage (1.x and 2.0 API)
    #   Octoprint::Files.copy(filename: "benchy.gcode", destination: "backup/benchy.gcode")
    #
    # @example Copy a local file to the printer's storage (2.0 API only)
    #   Octoprint::Files.copy(filename: "benchy.gcode", destination: "benchy.gco",
    #                         storage: Octoprint::Location::Printer)
    #
    # @param [String] filename        The name of the file or folder to copy
    # @param [String] destination     The destination path for the copy
    # @param [Location] location      The location of the source file
    # @param [Location, nil] storage  The storage to copy to. Defaults to the source's `location`. A different
    #                                 storage needs the 2.0 API and only works for files
    #
    # @return [T.untyped] 201 Created with file information (`name`, `path`, `origin`, `refs`, and `done` on 2.0)
    # @raise [Exceptions::UnsupportedFeatureError] when copying to another storage with the 1.x API
    #: (
    #|   filename: String,
    #|   destination: String,
    #|   ?location: Location,
    #|   ?storage: Location?
    #| ) -> untyped
    def self.copy(filename:, destination:, location: Location::Local, storage: nil)
      issue_command(filename: filename, command: "copy", location: location,
                    options: transfer_options(destination, location, storage))
    end

    # Moves a file or folder
    #
    # @example Rename a file (1.x and 2.0 API)
    #   Octoprint::Files.move(filename: "benchy.gcode", destination: "boat.gcode")
    #
    # @example Move a local file to the printer's storage (2.0 API only)
    #   Octoprint::Files.move(filename: "benchy.gcode", destination: "benchy.gco",
    #                         storage: Octoprint::Location::Printer)
    #
    # @param [String] filename        The name of the file or folder to move
    # @param [String] destination     The destination path for the move
    # @param [Location] location      The location of the source file
    # @param [Location, nil] storage  The storage to move to. Defaults to the source's `location`. A different
    #                                 storage needs the 2.0 API and only works for files
    #
    # @return [T.untyped] 201 Created with file information (`name`, `path`, `origin`, `refs`, and `done` on 2.0)
    # @raise [Exceptions::UnsupportedFeatureError] when moving to another storage with the 1.x API
    #: (
    #|   filename: String,
    #|   destination: String,
    #|   ?location: Location,
    #|   ?storage: Location?
    #| ) -> untyped
    def self.move(filename:, destination:, location: Location::Local, storage: nil)
      issue_command(filename: filename, command: "move", location: location,
                    options: transfer_options(destination, location, storage))
    end

    # Extracts the thumbnails embedded in G-code files again (2.0 API only)
    #
    # Only storages with the `thumbnails` capability support it, which is the local storage on OctoPrint 2.0.
    #
    # @example Refresh one file
    #   Octoprint::Files.refresh_thumbnails(filename: "benchy.gcode", force: true)
    #
    # @example Refresh the missing thumbnails of every file
    #   Octoprint::Files.refresh_thumbnails(recursive: true)
    #
    # @param [String, nil] filename   The file or folder to refresh. nil for the storage's root folder
    # @param [Location] location      The storage of the file or folder
    # @param [Boolean, nil] force     Extract the thumbnails even if the file already has some
    # @param [Boolean, nil] recursive For a folder, also refresh the files in its sub-folders
    #
    # @return [true] 204 No Content on success
    # @raise [Exceptions::UnsupportedFeatureError] with the 1.x API
    # @raise [Exceptions::BadRequestError] if the storage doesn't support thumbnails
    # @raise [Exceptions::NotFoundError] if the file or folder doesn't exist
    #: (
    #|   ?filename: String?,
    #|   ?location: Location,
    #|   ?force: bool?,
    #|   ?recursive: bool?
    #| ) -> untyped
    def self.refresh_thumbnails(filename: nil, location: Location::Local, force: nil, recursive: nil)
      require_feature!(:refresh_thumbnails)

      # The root folder is the storage's path with a trailing slash: /api/files/local/
      issue_command(filename: filename.to_s, command: "refresh_thumbnails", location: location,
                    options: { force: force, recursive: recursive }.compact)
    end

    # Deletes a file
    #
    # @param [String] filename        The name of the file to delete
    # @param [Location] location      The location of the file
    #
    # @return [T.untyped] 204 No Content on success
    #: (
    #|   filename: String,
    #|   ?location: Location
    #| ) -> untyped
    def self.delete_file(filename:, location: Location::Local)
      path = [@path, location.serialize, filename].compact.join("/")
      delete(path: path)
    end

    class << self
      private

      # Parameters of a copy or move. Sends `storage` only for another storage than the source's, which needs the
      # 2.0 API.
      #
      #: (String, Location, Location?) -> Hash[Symbol, untyped]
      def transfer_options(destination, location, storage)
        return { destination: destination } if storage.nil? || storage == location

        require_feature!(:cross_storage_move)
        { destination: destination, storage: storage.serialize }
      end
    end
  end
  # rubocop:enable Metrics/ClassLength
end
