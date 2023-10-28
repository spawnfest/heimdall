defmodule Heimdall.SecretsTest do
  use Heimdall.DataCase

  alias Heimdall.Factory
  alias Heimdall.Secrets

  @public_key_pem File.read!("./test/support/keys/example-public-key.pem")

  @private_key_pem File.read!("./test/support/keys/example-private-key.pem")

  describe "new/0" do
    test "returns an empty changeset with no errors" do
      changeset = Secrets.new()

      refute changeset.valid?

      assert changeset.errors == []
    end
  end

  describe "encrypt_and_create/1" do
    test "successfully encrypts and inserts a secret (for aes_gcm)" do
      raw = "supersecretpassword"

      params =
        Factory.valid_secret_params(%{
          encrypted_text: raw,
          encryption_algo: :aes_gcm
        })

      assert params[:encrypted_text] == raw

      {:ok, secret} = Secrets.encrypt_and_create(params)

      refute secret.encrypted_text == raw
    end

    test "successfully encrypts and inserts a secret (for plaintext)" do
      raw = "supersecretpassword"

      params =
        Factory.valid_secret_params(%{
          encrypted_text: raw,
          encryption_algo: :plaintext
        })

      assert params[:encrypted_text] == raw

      {:ok, secret} = Secrets.encrypt_and_create(params)

      assert secret.encrypted_text == raw
    end

    test "successfully encrypts and inserts a secret (for rsa)" do
      raw = "supersecretpassword"

      params =
        Factory.valid_secret_params(%{
          encrypted_text: raw,
          encryption_algo: :rsa,
          encryption_key: @public_key_pem
        })

      assert params[:encrypted_text] == raw

      {:ok, secret} = Secrets.encrypt_and_create(params)

      assert secret.encrypted_text != raw
    end

    test "doesn't encrypt text if invalid params" do
      raw = nil

      params =
        Factory.valid_secret_params(%{
          encrypted_text: raw,
          encryption_algo: :aes_gcm
        })

      {:error, changeset} = Secrets.encrypt_and_create(params)

      refute changeset.valid?
    end
  end

  describe "get/1" do
    test "returns secret with given id" do
      {:ok, secret} = Factory.encrypt_and_create()

      returned_val = Secrets.get(secret.id)

      assert secret.title == returned_val.title
    end
  end

  describe "decrypt/2" do
    test "successfully decrypts a secret (for aes_gcm)" do
      raw = "supersecretpassword"

      params =
        Factory.valid_secret_params(%{
          encrypted_text: raw,
          encryption_algo: :aes_gcm
        })

      {:ok, secret} = Secrets.encrypt_and_create(params)

      {:ok, decrypted} = Secrets.decrypt(secret, params[:encryption_key])

      assert decrypted == raw
    end

    test "successfully decrypts a secret (for plaintext)" do
      raw = "supersecretpassword"

      params =
        Factory.valid_secret_params(%{
          encrypted_text: raw,
          encryption_algo: :plaintext
        })

      {:ok, secret} = Secrets.encrypt_and_create(params)

      {:ok, decrypted} = Secrets.decrypt(secret, params[:encryption_key])

      assert decrypted == raw
    end

    test "successfully decrypts a secret (for rsa)" do
      raw = "supersecretpassword"

      params =
        Factory.valid_secret_params(%{
          encrypted_text: raw,
          encryption_algo: :rsa,
          encryption_key: @public_key_pem
        })

      {:ok, secret} = Secrets.encrypt_and_create(params)

      {:ok, decrypted} = Secrets.decrypt(secret, @private_key_pem)

      assert decrypted == raw
    end

    test "returns :error when bad key is provided for aes_gcm" do
      raw = "supersecretpassword"

      params =
        Factory.valid_secret_params(%{
          encrypted_text: raw,
          encryption_algo: :aes_gcm
        })

      {:ok, secret} = Secrets.encrypt_and_create(params)

      {:error, error} = Secrets.decrypt(secret, "bad_key")

      assert error == "Error in decryption"
    end

    test "returns :error when bad key is provided for rsa" do
      raw = "supersecretpassword"

      params =
        Factory.valid_secret_params(%{
          encrypted_text: raw,
          encryption_algo: :rsa,
          encryption_key: @public_key_pem
        })

      {:ok, secret} = Secrets.encrypt_and_create(params)

      {:error, error} = Secrets.decrypt(secret, "bad_key")

      assert error == "Error in decryption"
    end
  end
end
