# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::LegacyConverter do
  let(:converter) { Module.new { extend Octoprint::LegacyConverter } }
  let(:request) { Octoprint::ApiRequest.new(http_method: :get, path: "/api/job") }

  it "sends the request unchanged by default" do
    expect(converter.to_request(request)).to be request
  end

  it "returns the response unchanged by default" do
    response = { state: "Operational" }

    expect(converter.from_response(response, request)).to be response
  end
end
