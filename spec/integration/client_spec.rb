# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Client, type: :integration do
  include_context "with default Octoprint config"

  describe "#request" do
    subject(:current_user) { client.request("/api/currentuser") }

    let(:client) do
      described_class.new(host: host, api_key: api_key)
    end

    it "returns the body as a hash", vcr: { cassette_name: "currentuser" } do
      expect(current_user).to be_a Hash

      expect(current_user).to include(:groups)
      expect(current_user).to include(:name)
      expect(current_user).to include(:permissions)
    end
  end
end
