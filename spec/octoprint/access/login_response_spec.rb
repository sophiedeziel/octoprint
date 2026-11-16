# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Octoprint::Access::LoginResponse do
  let(:api_data) do
    {
      name: "sophie",
      active: true,
      admin: true,
      apikey: "ABC123",
      groups: %w[users admins],
      permissions: %w[ADMIN STATUS],
      needs: { group: %w[users admins], role: %w[admin user] },
      roles: %w[admin user],
      settings: {},
      user: true,
      session: "SESSION_KEY",
      _is_external_client: false,
      _login_mechanism: "apikey",
      _credentials_seen: "2026-11-16T03:56:31+00:00",
      _future_field: "value"
    }
  end

  describe ".deserialize" do
    subject(:login) { described_class.deserialize(api_data) }

    it "exposes the session key" do
      expect(login.session).to eq("SESSION_KEY")
    end

    it "maps _is_external_client to is_external_client" do
      expect(login.is_external_client).to be(false)
    end

    it "wraps the user record in a User" do
      expect(login.user).to be_a(Octoprint::Access::User)
      expect(login.user).to have_attributes(
        name: "sophie",
        active: true,
        admin: true,
        api_key: "ABC123",
        groups: %w[users admins],
        permissions: %w[ADMIN STATUS],
        needs_role: %w[admin user],
        roles: %w[admin user],
        settings: {},
        user: true
      )
    end

    it "maps the login mechanism and the credentials check time" do
      expect(login.login_mechanism).to eq("apikey")
      expect(login.credentials_seen).to eq("2026-11-16T03:56:31+00:00")
    end

    it "keeps the login fields out of the user record" do
      expect(login.user.extra).to eq({ _future_field: "value" })
    end

    it "handles a user record without unknown fields" do
      login = described_class.deserialize(name: "sophie", session: "SESSION_KEY", _is_external_client: true)

      expect(login.is_external_client).to be(true)
      expect(login.user.name).to eq("sophie")
      expect(login.user.extra).to be_nil
    end
  end

  describe "#initialize" do
    it "builds a login response from a User" do
      user = Octoprint::Access::User.new(name: "sophie")
      login = described_class.new(user: user, session: "SESSION_KEY", is_external_client: true)

      expect(login.user).to be(user)
      expect(login.session).to eq("SESSION_KEY")
      expect(login.is_external_client).to be(true)
    end
  end
end
