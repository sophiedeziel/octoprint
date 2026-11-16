# typed: true
# frozen_string_literal: true

module Octoprint
  class Job
    # Converts the 1.x job information to the OctoPrint 2.0 shape.
    #
    # The 2.0 API leaves out the fields that have no value, where 1.x sends them as `null`. With the 1.x API, this
    # converter drops the `null` fields of `GET /api/job` the same way, so a {Job} reads the same on both:
    #
    # - the top-level fields, the `job`, `job.file` and `progress` fields
    # - `filament`: the 1.x `{ length: null, volume: null }` of an idle printer is left out, as 2.0 does for a
    #   connected printer without a selected file
    #
    # It also fills `job.file.display` from `job.file.name` when a 1.x server doesn't send it. `job.file.upload`
    # has no 1.x equivalent and stays out. `lastPrintTime` and `averagePrintTime` are kept when they have a value:
    # only 1.x servers fill them.
    #
    # 2.0 servers answer the 1.x API with the same extra fields as the 2.0 API (`error`, `job.file.display`,
    # `job.file.upload`), and `null` for `lastPrintTime`, so the converter gives the same result for them.
    #
    # @see LegacyConverter
    module Legacy
      extend LegacyConverter

      # Drops the `null` fields of a 1.x job response.
      #
      # @param response [Hash, true] The parsed 1.x response
      # @param request [ApiRequest] The original request
      # @return [Hash, true] The response in the 2.0 shape
      #: (untyped, ApiRequest) -> untyped
      def self.from_response(response, request)
        return response unless request.http_method == :get && response.is_a?(Hash)

        job = response[:job]
        response = response.merge(job: convert_job(job)) if job.is_a?(Hash)
        progress = response[:progress]
        response = response.merge(progress: progress.compact) if progress.is_a?(Hash)
        response.compact
      end

      #: (Hash[Symbol, untyped]) -> Hash[Symbol, untyped]
      def self.convert_job(job)
        job = job.dup
        job[:file] = convert_file(job[:file]) if job[:file].is_a?(Hash)
        job[:filament] = job[:filament].compact.presence if job[:filament].is_a?(Hash)
        job.compact
      end
      private_class_method :convert_job

      #: (Hash[Symbol, untyped]) -> Hash[Symbol, untyped]
      def self.convert_file(file)
        file = file.compact
        file[:display] ||= file[:name] if file.key?(:name)
        file
      end
      private_class_method :convert_file
    end
  end
end
