# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::ApiRequest do
  subject(:request) { described_class.new(http_method: :post, path: "/api/connection", body: { command: "connect" }) }

  it "defaults to no query, headers or options" do
    expect(request).to have_attributes(query: {}, headers: {}, options: {})
  end

  it "defaults to no body" do
    expect(described_class.new(http_method: :get, path: "/api/job").body).to be_nil
  end

  it "is frozen" do
    expect(request).to be_frozen
  end

  describe "#with" do
    it "returns a copy with the changed attributes" do
      changed = request.with(body: { command: "fake_ack" })

      expect(changed).to have_attributes(http_method: :post, path: "/api/connection", body: { command: "fake_ack" })
      expect(request.body).to eq(command: "connect")
    end

    it "raises for an unknown attribute" do
      expect { request.with(verb: :get) }.to raise_error(ArgumentError)
    end
  end

  describe "#full_path" do
    it "is the path without a query" do
      expect(request.full_path).to eq "/api/connection"
    end

    it "appends the query string" do
      get = described_class.new(http_method: :get, path: "/api/printer", query: { exclude: "sd", history: true })

      expect(get.full_path).to eq "/api/printer?exclude=sd&history=true"
    end
  end

  describe "equality" do
    it "equals a request with the same attributes" do
      same = described_class.new(http_method: :post, path: "/api/connection", body: { command: "connect" })

      expect(request).to eq same
      expect(request).to eql same
      expect(request.hash).to eq same.hash
    end

    it "differs from a request with other attributes" do
      expect(request).not_to eq request.with(path: "/api/printer")
    end

    it "differs from other objects" do
      expect(request).not_to eq request.to_h
    end
  end
end
