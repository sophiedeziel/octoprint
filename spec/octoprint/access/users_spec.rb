# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Octoprint::Access::Users do
  include_context "with default Octoprint config"

  let(:client) { Octoprint::Client.new(host: host, api_key: api_key) }

  before do
    allow(Octoprint).to receive(:client).and_return(client)
    # Bypass BaseResource's client method type checking for tests
    allow(described_class).to receive(:client).and_return(client)
  end

  describe ".list" do
    it "fetches and deserializes users" do
      api_response = {
        users: [
          {
            name: "admin",
            active: true,
            admin: true,
            apikey: "ABC123",
            settings: {},
            groups: ["admins"],
            permissions: ["ADMIN"],
            needs: { group: ["admins"], role: ["admin"] },
            roles: ["admin"],
            user: false
          },
          {
            name: "john_doe",
            active: true,
            admin: false,
            apikey: "XYZ789",
            settings: { interface: { color: "dark" } },
            groups: ["operators"],
            permissions: %w[CONTROL MONITOR],
            needs: { group: ["operators"], role: %w[control monitor] },
            roles: ["user"],
            user: true
          }
        ]
      }

      allow(client).to receive(:request)
        .with("/api/access/users", { http_method: :get })
        .and_return(api_response)

      users = described_class.list

      expect(users).to be_an(Array)
      expect(users.length).to eq(2)

      admin_user = users.first
      expect(admin_user).to be_a(Octoprint::Access::User)
      expect(admin_user.name).to eq("admin")
      expect(admin_user.active).to be(true)
      expect(admin_user.admin).to be(true)
      expect(admin_user.api_key).to eq("ABC123")
      expect(admin_user.groups).to eq(["admins"])

      regular_user = users.last
      expect(regular_user.name).to eq("john_doe")
      expect(regular_user.active).to be(true)
      expect(regular_user.admin).to be(false)
      expect(regular_user.groups).to eq(["operators"])
      expect(regular_user.permissions).to eq(%w[CONTROL MONITOR])
    end
  end

  describe ".add" do
    it "creates a new user" do
      api_response = {
        users: [{
          name: "jane_doe",
          active: true,
          admin: false,
          apikey: "DEF456",
          settings: {},
          groups: ["users"],
          permissions: ["MONITOR"],
          needsRole: []
        }]
      }

      allow(client).to receive(:request)
        .with("/api/access/users", {
                http_method: :post,
                params: {
                  name: "jane_doe",
                  password: "secure_password",
                  active: true,
                  admin: false,
                  groups: ["users"],
                  permissions: ["MONITOR"]
                }
              })
        .and_return(api_response)

      user = described_class.add(
        name: "jane_doe",
        password: "secure_password",
        active: true,
        admin: false,
        groups: ["users"],
        permissions: ["MONITOR"]
      ).find { |u| u.name == "jane_doe" }

      expect(user).to be_a(Octoprint::Access::User)
      expect(user.name).to eq("jane_doe")
      expect(user.active).to be(true)
      expect(user.admin).to be(false)
      expect(user.groups).to eq(["users"])
      expect(user.permissions).to eq(["MONITOR"])
    end

    it "creates a user without optional parameters" do
      api_response = {
        users: [{
          name: "test_user",
          active: false,
          admin: true,
          apikey: "GHI789",
          settings: {},
          groups: [],
          permissions: [],
          needsRole: []
        }]
      }

      allow(client).to receive(:request)
        .with("/api/access/users", {
                http_method: :post,
                params: {
                  name: "test_user",
                  password: "password",
                  active: false,
                  admin: true
                }
              })
        .and_return(api_response)

      user = described_class.add(
        name: "test_user",
        password: "password",
        active: false,
        admin: true
      ).find { |u| u.name == "test_user" }

      expect(user).to be_a(Octoprint::Access::User)
      expect(user.name).to eq("test_user")
      expect(user.active).to be(false)
      expect(user.admin).to be(true)
    end

    it "omits admin from the payload when it isn't given (OctoPrint 2.0 removed it)" do
      api_response = {
        users: [{ name: "test_user", active: true, apikey: nil, groups: ["users"], has_password: true,
                  needs: { group: ["users"], role: ["files_list"] }, permissions: [], settings: {} }]
      }

      allow(client).to receive(:request)
        .with("/api/access/users", { http_method: :post,
                                     params: { name: "test_user", password: "password", active: true } })
        .and_return(api_response)

      user = described_class.add(name: "test_user", password: "password", active: true).first

      expect(user).to have_attributes(name: "test_user", admin: nil, has_password: true, admin?: false)
    end
  end

  describe ".get" do
    it "fetches a specific user" do
      api_response = {
        name: "john_doe",
        active: true,
        admin: false,
        apikey: "XYZ789",
        settings: { interface: { color: "dark" } },
        groups: ["operators"],
        permissions: %w[CONTROL MONITOR],
        needsRole: []
      }

      allow(client).to receive(:request)
        .with("/api/access/users/john_doe", { http_method: :get })
        .and_return(api_response)

      user = described_class.get(username: "john_doe")

      expect(user).to be_a(Octoprint::Access::User)
      expect(user.name).to eq("john_doe")
      expect(user.active).to be(true)
      expect(user.groups).to eq(["operators"])
    end
  end

  describe ".update" do
    it "updates a user" do
      api_response = {
        users: [{
          name: "john_doe",
          active: false,
          admin: false,
          apikey: "XYZ789",
          settings: { interface: { color: "dark" } },
          groups: %w[operators users],
          permissions: %w[CONTROL MONITOR],
          needsRole: []
        }]
      }

      allow(client).to receive(:request)
        .with("/api/access/users/john_doe", {
                http_method: :put,
                params: {
                  active: false,
                  groups: %w[operators users]
                }
              })
        .and_return(api_response)

      user = described_class.update(
        username: "john_doe",
        params: {
          active: false,
          groups: %w[operators users]
        }
      ).find { |u| u.name == "john_doe" }

      expect(user).to be_a(Octoprint::Access::User)
      expect(user.active).to be(false)
      expect(user.groups).to eq(%w[operators users])
    end
  end

  describe ".delete" do
    it "deletes a user" do
      allow(client).to receive(:request)
        .with("/api/access/users/john_doe", { http_method: :delete })
        .and_return(nil)

      result = described_class.delete(username: "john_doe")

      expect(result).to be_nil
    end

    it "calls super when no username is provided" do
      allow(client).to receive(:request)
        .with("/api/access/users", {
                http_method: :delete,
                body: nil,
                headers: {},
                options: {}
              })
        .and_return(true)

      result = described_class.delete(path: "/api/access/users")

      expect(result).to be(true)
    end
  end

  describe ".change_password" do
    it "changes a user's password" do
      allow(client).to receive(:request)
        .with("/api/access/users/john_doe/password", {
                http_method: :post,
                params: { password: "new_password" }
              })
        .and_return(nil)

      result = described_class.change_password(
        username: "john_doe",
        password: "new_password"
      )

      expect(result).to be_nil
    end
  end

  describe ".get_settings" do
    it "gets user settings" do
      settings = { interface: { color: "dark" }, webcam: { rotate90: true } }

      allow(client).to receive(:request)
        .with("/api/access/users/john_doe/settings", { http_method: :get })
        .and_return(settings)

      result = described_class.get_settings(username: "john_doe")

      expect(result).to eq(settings)
    end
  end

  describe ".update_settings" do
    it "updates user settings" do
      settings = { interface: { color: "light" } }
      updated_settings = { interface: { color: "light" }, webcam: { rotate90: true } }

      allow(client).to receive(:request)
        .with("/api/access/users/john_doe/settings", {
                http_method: :patch,
                params: settings
              })
        .and_return(updated_settings)

      result = described_class.update_settings(
        username: "john_doe",
        settings: settings
      )

      expect(result).to eq(updated_settings)
    end
  end

  describe ".generate_api_key" do
    it "generates a new API key" do
      api_response = { apikey: "NEW_API_KEY_123" }

      allow(client).to receive(:request)
        .with("/api/access/users/john_doe/apikey", { http_method: :post })
        .and_return(api_response)

      api_key = described_class.generate_api_key(username: "john_doe")

      expect(api_key).to eq("NEW_API_KEY_123")
    end
  end

  describe ".delete_api_key" do
    it "deletes a user's API key" do
      allow(client).to receive(:request)
        .with("/api/access/users/john_doe/apikey", { http_method: :delete })
        .and_return(nil)

      result = described_class.delete_api_key(username: "john_doe")

      expect(result).to be_nil
    end
  end

  describe ".login" do
    let(:api_response) do
      {
        name: "john_doe",
        active: true,
        admin: false,
        groups: ["users"],
        permissions: ["STATUS"],
        session: "SESSION_KEY",
        _is_external_client: false
      }
    end

    def stub_login(body)
      allow(client).to receive(:request)
        .with("/api/login", http_method: :post, body: body)
        .and_return(api_response)
    end

    it "does a passive login without credentials" do
      stub_login({ passive: true })

      login = described_class.login

      expect(login).to be_a(Octoprint::Access::LoginResponse)
      expect(login.user.name).to eq("john_doe")
      expect(login.session).to eq("SESSION_KEY")
      expect(login.is_external_client).to be(false)
    end

    it "sends the credentials as user and pass for an active login" do
      stub_login({ user: "john_doe", pass: "secret" })

      login = described_class.login(username: "john_doe", password: "secret")

      expect(login.user.name).to eq("john_doe")
    end

    it "sends remember only when it is true" do
      stub_login({ user: "john_doe", pass: "secret", remember: true })

      login = described_class.login(username: "john_doe", password: "secret", remember: true)

      expect(login.session).to eq("SESSION_KEY")
    end

    it "raises ArgumentError when only the username is given" do
      expect { described_class.login(username: "john_doe") }
        .to raise_error(ArgumentError, "username and password must be given together")
    end

    it "raises ArgumentError when only the password is given" do
      expect { described_class.login(password: "secret") }
        .to raise_error(ArgumentError, "username and password must be given together")
    end

    it "raises ArgumentError when remember is set on a passive login" do
      expect { described_class.login(remember: true) }
        .to raise_error(ArgumentError, "remember only applies to an active login")
    end

    it "raises AuthenticationError when the credentials are rejected" do
      allow(client).to receive(:request)
        .and_raise(Octoprint::Exceptions::AuthenticationError, "[403] Forbidden")

      expect { described_class.login(username: "john_doe", password: "wrong") }
        .to raise_error(Octoprint::Exceptions::AuthenticationError)
    end
  end

  describe ".logout" do
    it "returns true when OctoPrint answers 204" do
      allow(client).to receive(:request)
        .with("/api/logout", http_method: :post)
        .and_return(true)

      expect(described_class.logout).to be(true)
    end

    it "returns true when OctoPrint answers 200 with the guest's needs" do
      allow(client).to receive(:request)
        .with("/api/logout", http_method: :post)
        .and_return({ needs: { group: ["guests"] } })

      expect(described_class.logout).to be(true)
    end
  end
end
