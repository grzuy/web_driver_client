defmodule WebDriverClient.Middleware.JSONParsingErrorTranslator do
  @moduledoc false

  alias WebDriverClient.UnexpectedResponseFormatError

  @behaviour Tesla.Middleware

  @impl true
  def call(env, next, _opts) do
    with {:error, {Tesla.Middleware.JSON, :decode, reason}} <- Tesla.run(env, next) do
      {:error, UnexpectedResponseFormatError.exception(reason: reason)}
    end
  end
end