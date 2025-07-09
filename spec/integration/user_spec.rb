# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::User, type: :integration do
  include_context "with default Octoprint config"

  describe ".current" do
    it "returns a User object", vcr: { cassette_name: "currentuser" } do
      Octoprint.configure(host: host, api_key: api_key)
      user = described_class.current

      expect(user).to be_a(described_class)
      expect(user.name).to be_a(String)
      expect(user.groups).to be_an(Array)
      expect(user.permissions).to be_an(Array)
    end
  end
end
