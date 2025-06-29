# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::User do
  describe ".deserialize" do
    it "deserializes API response correctly" do
      api_data = {
        name: "admin",
        permissions: %w[STATUS CONNECTION WEBCAM SYSTEM SETTINGS_READ SETTINGS],
        groups: %w[admin users],
        unknown_field: "future_value"
      }

      user = described_class.deserialize(api_data)

      expect(user.name).to eq("admin")
      expect(user.permissions).to eq(%w[STATUS CONNECTION WEBCAM SYSTEM SETTINGS_READ SETTINGS])
      expect(user.groups).to eq(%w[admin users])
      expect(user.extra).to eq({ unknown_field: "future_value" })
    end

    it "handles minimal data" do
      api_data = {
        name: "user"
      }

      user = described_class.deserialize(api_data)

      expect(user.name).to eq("user")
      expect(user.permissions).to be_nil
      expect(user.groups).to be_nil
      expect(user.extra).to be_nil
    end
  end
end
