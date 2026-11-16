# typed: true
# frozen_string_literal: true

module Octoprint
  class Job
    # The file that is the target of the current print job.
    #
    # Every attribute is `nil` when no file is selected: OctoPrint 2.0 leaves out empty fields, and the 1.x
    # responses are converted the same way (see {Job::Legacy}).
    #
    # @example Access the file of the current job
    #   file = Octoprint::Job.get.information.file
    #   puts "Printing #{file.display_name} (#{file.path}) from #{file.origin}"
    #   puts "Uploading to the printer's storage" if file.upload
    #
    # @see https://docs.octoprint.org/en/master/api/datamodel.html#sec-api-datamodel-jobs-job
    class File
      include AutoInitializable
      include Deserializable

      # @!attribute [r] name
      #   @return [String, nil] The name of the file
      auto_attr :name, type: String

      # @!attribute [r] display_name
      #   @return [String, nil] The name of the file as displayed in OctoPrint (the API's `display` field).
      #     Filled from {#name} on 1.x servers that don't send it.
      auto_attr :display_name, type: String

      # @!attribute [r] path
      #   @return [String, nil] The path of the file within its storage
      auto_attr :path, type: String

      # @!attribute [r] origin
      #   @return [String, nil] The storage the file is on: `"local"`, or the printer's storage
      #     (`"sdcard"` on 1.x, `"printer"` on 2.0)
      auto_attr :origin, type: String

      # @!attribute [r] size
      #   @return [Integer, nil] The size of the file in bytes. Only available for local files or SD card files
      #     while printing
      auto_attr :size, type: Integer

      # @!attribute [r] date_timestamp
      #   @return [Integer, nil] The upload date of the file, as a Unix timestamp (the API's `date` field)
      auto_attr :date_timestamp, type: Integer

      # @!attribute [r] upload
      #   @return [Boolean, nil] OctoPrint 2.0: `true` when the job uploads the file to the printer's storage
      #     instead of printing it, `false` for a print. Always `nil` on 1.x servers.
      auto_attr :upload, type: Types::NilableBoolean

      # @!attribute [r] extra
      #   @return [Hash] Any additional fields returned by the API
      auto_attr :extra, type: Hash

      auto_initialize!

      deserialize_config do
        # `display` would override Object#display
        rename display: :display_name, date: :date_timestamp
      end

      # The upload date of the file.
      #
      # @example
      #   Octoprint::Job.get.information.file.date # => 2026-11-16 01:08:11 -0500
      #
      # @return [Time, nil] The upload date, or nil when no file is selected
      #: -> Time?
      def date
        return nil unless date_timestamp

        Time.at(date_timestamp)
      end

      # The file as a hash with the API's keys, leaving out the empty ones.
      #
      # @example
      #   file.to_h # => { date: 1794809291, display: "job_test.gcode", name: "job_test.gcode", ... }
      #
      # @return [Hash{Symbol => Object}]
      #: -> Hash[Symbol, untyped]
      def to_h
        {
          date: date_timestamp, display: display_name, name: name, origin: origin, path: path, size: size,
          upload: upload
        }.compact.merge(extra || {})
      end

      # Reads a field by its API key, like the hash {Information#file} used to be.
      #
      # @deprecated {Information#file} is a {Job::File} now: use its readers, e.g. `file.name` or
      #   `file.display_name` instead of `file[:name]` or `file[:display]`.
      # @example
      #   file[:name] # => "job_test.gcode"
      #
      # @param key [Symbol] An API key, e.g. `:name`, `:display` or `:date`
      # @return [Object, nil] The value, or nil when the file doesn't have it
      #: (Symbol key) -> untyped
      def [](key)
        warn_hash_access("[]")
        to_h[key]
      end

      # Fetches a field by its API key, like the hash {Information#file} used to be. Takes the API key and an
      # optional default or block, as `Hash#fetch` does.
      #
      # @deprecated Use the readers of {Job::File}, e.g. `file.name`.
      # @example
      #   file.fetch(:name) # => "job_test.gcode"
      #   file.fetch(:upload, false)
      #
      # @return [Object]
      # @raise [KeyError] if the file doesn't have the field and no default is given
      #: (*untyped) ?{ (Symbol) -> untyped } -> untyped
      def fetch(*, &)
        warn_hash_access("fetch")
        T.unsafe(to_h).fetch(*, &)
      end

      # Digs into a field by its API key, like the hash {Information#file} used to be.
      #
      # @deprecated Use the readers of {Job::File}, e.g. `file.name`.
      # @example
      #   file.dig(:name) # => "job_test.gcode"
      #
      # @param keys [Array<Symbol>] The API key, then the keys to dig into its value
      # @return [Object, nil]
      #: (*untyped) -> untyped
      def dig(*keys)
        warn_hash_access("dig")
        T.unsafe(to_h).dig(*keys)
      end

      # Whether the file has a field, like the hash {Information#file} used to be.
      #
      # @deprecated Use the readers of {Job::File} and check them for `nil`.
      # @example
      #   file.key?(:name) # => true
      #
      # @param key [Symbol] An API key
      # @return [Boolean]
      #: (Symbol key) -> bool
      def key?(key)
        warn_hash_access("key?")
        to_h.key?(key)
      end

      private

      #: (String) -> void
      def warn_hash_access(method)
        Deprecation.warn_once("Octoprint::Job::File##{method}",
                              "Job::Information#file is a Job::File now, use its readers " \
                              "(file.name, file.display_name, ...)")
      end
    end
  end
end
