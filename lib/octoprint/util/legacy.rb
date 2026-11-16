# typed: true
# frozen_string_literal: true

module Octoprint
  class Util
    # Converts the 2.0 util API requests to the 1.x API. See {LegacyConverter}.
    #
    # OctoPrint 2.0 renamed the content type filters of the URL test. The 1.x API only knows the old names:
    # - `content_type_allowlist` → `content_type_whitelist`
    # - `content_type_blocklist` → `content_type_blacklist`
    #
    # OctoPrint 1.11 fails with a 500 error when it receives `content_type_blacklist` without
    # `content_type_whitelist`, so the converter adds a whitelist that allows every content type (`*/*`).
    module Legacy
      extend LegacyConverter

      # 2.0 name => 1.x name of the URL test parameters
      RENAMED = {
        content_type_allowlist: :content_type_whitelist,
        content_type_blocklist: :content_type_blacklist
      }.freeze

      # Whitelist that lets every content type through
      ALLOW_ALL = ["*/*"].freeze

      # Renames the content type filters of a URL test to the 1.x names
      #
      # @param request [ApiRequest]
      # @return [ApiRequest]
      #: (ApiRequest) -> ApiRequest
      def self.to_request(request)
        body = request.body
        return request unless body.is_a?(Hash) && body[:command] == "url"

        body = body.to_h { |key, value| [RENAMED.fetch(key, key), value] }
        body[:content_type_whitelist] ||= ALLOW_ALL if body.key?(:content_type_blacklist)
        request.with(body: body)
      end
    end
  end
end
