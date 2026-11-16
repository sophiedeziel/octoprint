# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Printer::Storage::Legacy do
  def request(http_method, path, body: nil)
    Octoprint::ApiRequest.new(http_method: http_method, path: path, body: body)
  end

  describe ".to_request" do
    it "gets the state from /api/printer/sd" do
      converted = described_class.to_request(request(:get, "/api/printer/storage"))

      expect(converted).to eq(request(:get, "/api/printer/sd"))
    end

    it "posts commands to /api/printer/sd" do
      original = request(:post, "/api/printer/storage", body: { command: "init" })

      expect(described_class.to_request(original)).to eq(request(:post, "/api/printer/sd", body: { command: "init" }))
    end

    it "leaves other paths alone" do
      original = request(:get, "/api/printer")

      expect(described_class.to_request(original)).to be(original)
    end
  end

  describe ".from_response" do
    # GET /api/printer/sd on OctoPrint 1.11.8 (spec/cassettes/printer/storage/get.yml)
    it "returns the state unchanged: 1.x and 2.0 have the same shape" do
      response = { ready: true }

      expect(described_class.from_response(response, request(:get, "/api/printer/storage"))).to be(response)
    end

    it "returns command results unchanged" do
      expect(described_class.from_response(true, request(:post, "/api/printer/storage"))).to be(true)
    end
  end
end
