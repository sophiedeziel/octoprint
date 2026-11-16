# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Printer::Legacy do
  def request(query = {})
    Octoprint::ApiRequest.new(http_method: :get, path: "/api/printer", query: query)
  end

  it "is the printer's legacy converter" do
    expect(Octoprint::Printer.legacy_converter).to be(described_class)
  end

  it "isn't used by the printer's sub-resources" do
    expect(Octoprint::Printer::Tool.legacy_converter).to be_nil
  end

  describe ".to_request" do
    it "excludes sd instead of storage" do
      converted = described_class.to_request(request(exclude: "temperature,storage"))

      expect(converted).to eq(request(exclude: "temperature,sd"))
    end

    it "keeps the other query parameters" do
      converted = described_class.to_request(request(history: true, limit: 2, exclude: "storage"))

      expect(converted.query).to eq(history: true, limit: 2, exclude: "sd")
    end

    it "keeps the other excluded fields" do
      converted = described_class.to_request(request(exclude: "temperature,state"))

      expect(converted.query).to eq(exclude: "temperature,state")
    end

    it "sends a request without excluded fields unchanged" do
      original = request(history: true)

      expect(described_class.to_request(original)).to be(original)
    end
  end

  describe ".from_response" do
    # GET /api/printer on OctoPrint 1.11.8 (spec/cassettes/printer/get.yml), temperatures trimmed
    let(:response) do
      {
        sd: { ready: true },
        state: {
          error: "",
          flags: { operational: true, ready: true, sd_ready: true },
          text: "Operational"
        },
        temperature: { tool0: { actual: 21.3, offset: 0, target: 0.0 } }
      }
    end

    it "renames sd to storage" do
      converted = described_class.from_response(response, request)

      expect(converted.keys).to contain_exactly(:storage, :state, :temperature)
      expect(converted[:storage]).to eq(ready: true)
    end

    it "keeps the other fields" do
      converted = described_class.from_response(response, request)

      expect(converted.except(:storage)).to eq(response.except(:sd))
    end

    it "doesn't modify the response it receives" do
      described_class.from_response(response, request)

      expect(response).to have_key(:sd)
    end

    it "returns a state without sd unchanged" do
      state = { state: { text: "Operational" } }

      expect(described_class.from_response(state, request(exclude: "storage"))).to eq(state)
    end

    it "returns responses that aren't a hash unchanged" do
      expect(described_class.from_response(true, request)).to be(true)
    end
  end
end
