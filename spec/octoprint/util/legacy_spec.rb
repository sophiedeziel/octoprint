# typed: false
# frozen_string_literal: true

RSpec.describe Octoprint::Util::Legacy do
  def request(body)
    Octoprint::ApiRequest.new(http_method: :post, path: "/api/util/test", body: body)
  end

  describe ".to_request" do
    it "renames the allowlist to the 1.x whitelist" do
      converted = described_class.to_request(
        request(command: "url", url: "https://httpbin.org/json", content_type_allowlist: ["text/html"])
      )

      expect(converted.body).to eq(command: "url", url: "https://httpbin.org/json",
                                   content_type_whitelist: ["text/html"])
    end

    it "renames both lists" do
      converted = described_class.to_request(
        request(command: "url", url: "u", content_type_allowlist: ["image/*"], content_type_blocklist: ["image/gif"])
      )

      expect(converted.body).to eq(command: "url", url: "u", content_type_whitelist: ["image/*"],
                                   content_type_blacklist: ["image/gif"])
    end

    # OctoPrint 1.11 answers 500 to a blacklist without a whitelist
    it "allows every content type when only the blocklist is given" do
      converted = described_class.to_request(
        request(command: "url", url: "u", content_type_blocklist: ["application/json"])
      )

      expect(converted.body).to eq(command: "url", url: "u", content_type_blacklist: ["application/json"],
                                   content_type_whitelist: ["*/*"])
    end

    it "sends a URL test without content type filters unchanged" do
      original = request(command: "url", url: "u", method: "GET")

      expect(described_class.to_request(original)).to eq original
    end

    it "sends the other tests unchanged" do
      original = request(command: "path", path: "/tmp")

      expect(described_class.to_request(original)).to eq original
    end

    it "sends a request without a body unchanged" do
      original = Octoprint::ApiRequest.new(http_method: :get, path: "/api/util/test")

      expect(described_class.to_request(original)).to be original
    end
  end
end
