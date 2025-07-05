# typed: true
# frozen_string_literal: true

RSpec.describe Octoprint::Exceptions do
  describe "exception hierarchy" do
    it "defines base Error class" do
      expect(described_class::Error).to be < StandardError
    end

    it "defines AuthenticationError as child of Error" do
      expect(described_class::AuthenticationError).to be < described_class::Error
    end

    it "defines BadRequestError as child of Error" do
      expect(described_class::BadRequestError).to be < described_class::Error
    end

    it "defines MissingCredentialsError as child of Error" do
      expect(described_class::MissingCredentialsError).to be < described_class::Error
    end

    it "defines InternalServerError as child of Error" do
      expect(described_class::InternalServerError).to be < described_class::Error
    end

    it "defines UnknownError as child of Error" do
      expect(described_class::UnknownError).to be < described_class::Error
    end

    it "defines ConflictError as child of Error" do
      expect(described_class::ConflictError).to be < described_class::Error
    end

    it "defines UnsupportedMediaTypeError as child of Error" do
      expect(described_class::UnsupportedMediaTypeError).to be < described_class::Error
    end

    it "defines NotFoundError as child of Error" do
      expect(described_class::NotFoundError).to be < described_class::Error
    end
  end

  describe "exception behavior" do
    describe "Error" do
      it "can be raised with a message" do
        expect { raise described_class::Error, "test message" }.to raise_error(described_class::Error, "test message")
      end

      it "is a StandardError" do
        error = described_class::Error.new("test")
        expect(error).to be_a(StandardError)
      end
    end

    describe "AuthenticationError" do
      it "can be raised and caught as specific type" do
        expect do
          raise described_class::AuthenticationError, "Invalid API key"
        end.to raise_error(described_class::AuthenticationError, "Invalid API key")
      end

      it "can be caught as base Error type" do
        expect do
          raise described_class::AuthenticationError, "Invalid API key"
        end.to raise_error(described_class::Error)
      end
    end

    describe "BadRequestError" do
      it "can be raised with error message" do
        expect do
          raise described_class::BadRequestError, "Invalid parameters"
        end.to raise_error(described_class::BadRequestError, "Invalid parameters")
      end
    end

    describe "MissingCredentialsError" do
      it "can be raised when credentials are missing" do
        expect do
          raise described_class::MissingCredentialsError, "No API key provided"
        end.to raise_error(described_class::MissingCredentialsError, "No API key provided")
      end
    end

    describe "InternalServerError" do
      it "can be raised for server errors" do
        expect do
          raise described_class::InternalServerError, "Server error"
        end.to raise_error(described_class::InternalServerError, "Server error")
      end
    end

    describe "UnknownError" do
      it "can be raised for unknown errors" do
        expect do
          raise described_class::UnknownError, "Unknown error occurred"
        end.to raise_error(described_class::UnknownError, "Unknown error occurred")
      end
    end

    describe "ConflictError" do
      it "can be raised for conflict situations" do
        expect do
          raise described_class::ConflictError, "Resource conflict"
        end.to raise_error(described_class::ConflictError, "Resource conflict")
      end
    end

    describe "UnsupportedMediaTypeError" do
      it "can be raised for unsupported media types" do
        expect do
          raise described_class::UnsupportedMediaTypeError, "Unsupported file type"
        end.to raise_error(described_class::UnsupportedMediaTypeError, "Unsupported file type")
      end
    end

    describe "NotFoundError" do
      it "can be raised for not found resources" do
        expect do
          raise described_class::NotFoundError, "Resource not found"
        end.to raise_error(described_class::NotFoundError, "Resource not found")
      end
    end
  end

  describe "polymorphic exception handling" do
    it "allows catching all custom exceptions as Error" do
      [
        described_class::AuthenticationError,
        described_class::BadRequestError,
        described_class::MissingCredentialsError,
        described_class::InternalServerError,
        described_class::UnknownError,
        described_class::ConflictError,
        described_class::UnsupportedMediaTypeError,
        described_class::NotFoundError
      ].each do |exception_class|
        expect do
          raise exception_class, "test"
        rescue described_class::Error
          # Successfully caught as base Error type
        end.not_to raise_error
      end
    end
  end
end
