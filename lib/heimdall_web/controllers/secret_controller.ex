defmodule HeimdallWeb.SecretController do
  use HeimdallWeb, :controller

  alias Heimdall.Secrets

  def new(conn, _params) do
    changeset = Secrets.new()
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"secret" => params}) do
    case Secrets.encrypt_and_create(params) do
      {:ok, secret} ->
        conn
        |> put_flash(:info, "Secret successfully created")
        |> redirect(to: ~p"/successfully_created?secret_id=#{secret.id}")

      {:error, changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def successfully_created(conn, %{"secret_id" => secret_id}) do
    render(conn, :successfully_created, secret_id: secret_id)
  end

  def show(conn, %{"secret_id" => secret_id}) do
    case Secrets.get(secret_id) do
      nil ->
        text(conn, "Not Found")

      secret ->
        render(conn, :show, secret: secret)
    end
  end
end
