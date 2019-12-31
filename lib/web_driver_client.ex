defmodule WebDriverClient do
  @moduledoc """
  Webdriver API client.
  """

  import WebDriverClient.CompatibilityMacros
  import WebDriverClient.Guards

  alias WebDriverClient.Config
  alias WebDriverClient.Element
  alias WebDriverClient.HTTPClientError
  alias WebDriverClient.JSONWireProtocolClient
  alias WebDriverClient.LogEntry
  alias WebDriverClient.Session
  alias WebDriverClient.Size
  alias WebDriverClient.UnexpectedResponseError
  alias WebDriverClient.W3CWireProtocolClient
  alias WebDriverClient.WebDriverError

  @type config_opt :: {:config, Config.t()}
  @type url :: String.t()
  @type basic_reason ::
          HTTPClientError.t()
          | UnexpectedResponseError.t()
          | WebDriverError.t()

  @doc """
  Starts a new session
  """
  @spec start_session(map(), [config_opt]) :: {:ok, Session.t()} | {:error, basic_reason}
  def start_session(payload, opts) when is_list(opts) and is_map(payload) do
    config = Keyword.fetch!(opts, :config)

    case config do
      %Config{protocol: :jwp} ->
        case JSONWireProtocolClient.start_session(payload, config) do
          {:ok, session} ->
            {:ok, session}

          {:error, error} ->
            {:error, to_error(error)}
        end

      %Config{protocol: :w3c} ->
        case W3CWireProtocolClient.start_session(payload, config) do
          {:ok, session} ->
            {:ok, session}

          {:error, error} ->
            {:error, to_error(error)}
        end
    end
  end

  @doc """
  Returns the list of sessions
  """
  doc_metadata subject: :sessions
  @spec fetch_sessions([config_opt]) :: {:ok, [Session.t()]} | {:error, basic_reason}
  def fetch_sessions(opts) when is_list(opts) do
    config = Keyword.fetch!(opts, :config)

    case config do
      %Config{protocol: :jwp} ->
        case JSONWireProtocolClient.fetch_sessions(config) do
          {:ok, sessions} ->
            {:ok, sessions}

          {:error, error} ->
            {:error, to_error(error)}
        end

      %Config{protocol: :w3c} ->
        case W3CWireProtocolClient.fetch_sessions(config) do
          {:ok, session} ->
            {:ok, session}

          {:error, error} ->
            {:error, to_error(error)}
        end
    end
  end

  @doc """
  Ends a session
  """
  doc_metadata subject: :sessions
  @spec end_session(Session.t()) :: :ok | {:error, basic_reason}
  def end_session(%Session{config: %Config{protocol: :jwp}} = session) do
    case JSONWireProtocolClient.end_session(session) do
      :ok ->
        :ok

      {:error, error} ->
        {:error, to_error(error)}
    end
  end

  def end_session(%Session{config: %Config{protocol: :w3c}} = session) do
    case W3CWireProtocolClient.end_session(session) do
      :ok ->
        :ok

      {:error, error} ->
        {:error, to_error(error)}
    end
  end

  @doc """
  Navigates the browser to the given url
  """
  doc_metadata subject: :navigation
  @spec navigate_to(Session.t(), url) :: :ok | {:error, basic_reason}

  def navigate_to(%Session{config: %Config{protocol: :jwp}} = session, url)
      when is_url(url) do
    case JSONWireProtocolClient.navigate_to(session, url) do
      :ok ->
        :ok

      {:error, error} ->
        {:error, to_error(error)}
    end
  end

  def navigate_to(%Session{config: %Config{protocol: :w3c}} = session, url)
      when is_url(url) do
    case W3CWireProtocolClient.navigate_to(session, url) do
      :ok ->
        :ok

      {:error, error} ->
        {:error, to_error(error)}
    end
  end

  @doc """
  Returns the web browsers current url
  """
  doc_metadata subject: :navigation
  @spec fetch_current_url(Session.t()) :: {:ok, url} | {:error, basic_reason}
  def fetch_current_url(%Session{config: %Config{protocol: :jwp}} = session) do
    case JSONWireProtocolClient.fetch_current_url(session) do
      {:ok, current_url} ->
        {:ok, current_url}

      {:error, error} ->
        {:error, to_error(error)}
    end
  end

  def fetch_current_url(%Session{config: %Config{protocol: :w3c}} = session) do
    case W3CWireProtocolClient.fetch_current_url(session) do
      {:ok, current_url} ->
        {:ok, current_url}

      {:error, error} ->
        {:error, to_error(error)}
    end
  end

  @doc """
  Returns the size of the current window
  """
  @spec fetch_window_size(Session.t()) :: {:ok, Size.t()} | {:error, basic_reason}
  def fetch_window_size(%Session{config: %Config{protocol: :jwp}} = session) do
    case JSONWireProtocolClient.fetch_window_size(session) do
      {:ok, size} ->
        {:ok, size}

      {:error, error} ->
        {:error, to_error(error)}
    end
  end

  def fetch_window_size(%Session{config: %Config{protocol: :w3c}} = session) do
    case W3CWireProtocolClient.fetch_window_rect(session) do
      {:ok, %W3CWireProtocolClient.Rect{width: width, height: height}} ->
        {:ok, %Size{width: width, height: height}}

      {:error, error} ->
        {:error, to_error(error)}
    end
  end

  @type element_location_strategy :: :css_selector | :xpath
  @type element_selector :: String.t()

  @doc """
  Finds the elements using the given search strategy
  """
  doc_metadata subject: :elements

  @spec find_elements(Session.t(), element_location_strategy, element_selector) ::
          {:ok, [Element.t()]} | {:error, basic_reason}
  def find_elements(
        %Session{config: %Config{protocol: :jwp}} = session,
        element_location_strategy,
        element_selector
      )
      when is_element_location_strategy(element_location_strategy) and
             is_element_selector(element_selector) do
    case JSONWireProtocolClient.find_elements(
           session,
           element_location_strategy,
           element_selector
         ) do
      {:ok, elements} ->
        {:ok, elements}

      {:error, error} ->
        {:error, to_error(error)}
    end
  end

  def find_elements(
        %Session{config: %Config{protocol: :w3c}} = session,
        element_location_strategy,
        element_selector
      )
      when is_element_location_strategy(element_location_strategy) and
             is_element_selector(element_selector) do
    case W3CWireProtocolClient.find_elements(session, element_location_strategy, element_selector) do
      {:ok, elements} ->
        {:ok, elements}

      {:error, error} ->
        {:error, to_error(error)}
    end
  end

  @doc """
  Finds elements that are children of the given element
  """
  doc_metadata subject: :elements

  @spec find_elements_from_element(
          Session.t(),
          Element.t(),
          element_location_strategy,
          element_selector
        ) :: {:ok, [Element.t()] | {:error, basic_reason}}
  def find_elements_from_element(
        %Session{config: %Config{protocol: :jwp}} = session,
        %Element{} = element,
        element_location_strategy,
        element_selector
      )
      when is_element_location_strategy(element_location_strategy) and
             is_element_selector(element_selector) do
    case JSONWireProtocolClient.find_elements_from_element(
           session,
           element,
           element_location_strategy,
           element_selector
         ) do
      {:ok, elements} ->
        {:ok, elements}

      {:error, error} ->
        {:error, to_error(error)}
    end
  end

  def find_elements_from_element(
        %Session{config: %Config{protocol: :w3c}} = session,
        %Element{} = element,
        element_location_strategy,
        element_selector
      )
      when is_element_location_strategy(element_location_strategy) and
             is_element_selector(element_selector) do
    case W3CWireProtocolClient.find_elements_from_element(
           session,
           element,
           element_location_strategy,
           element_selector
         ) do
      {:ok, elements} ->
        {:ok, elements}

      {:error, error} ->
        {:error, to_error(error)}
    end
  end

  @type size_opt :: {:width, pos_integer} | {:height, pos_integer}

  @doc """
  Sets the size of the window
  """
  @spec set_window_size(Session.t(), [size_opt]) :: :ok | {:error, basic_reason}
  def set_window_size(session, opts \\ [])

  def set_window_size(%Session{config: %Config{protocol: :jwp}} = session, opts)
      when is_list(opts) do
    case JSONWireProtocolClient.set_window_size(session, opts) do
      :ok ->
        :ok

      {:error, error} ->
        {:error, to_error(error)}
    end
  end

  def set_window_size(%Session{config: %Config{protocol: :w3c}} = session, opts)
      when is_list(opts) do
    case W3CWireProtocolClient.set_window_rect(session, opts) do
      :ok ->
        :ok

      {:error, error} ->
        {:error, to_error(error)}
    end
  end

  @type log_type :: String.t()

  @doc """
  Fetches the log types from the server
  """
  doc_metadata subject: :logging
  @spec fetch_log_types(Session.t()) :: {:ok, [log_type]} | {:error, basic_reason()}
  def fetch_log_types(%Session{config: %Config{protocol: :jwp}} = session) do
    case JSONWireProtocolClient.fetch_log_types(session) do
      {:ok, log_types} ->
        {:ok, log_types}

      {:error, error} ->
        {:error, to_error(error)}
    end
  end

  def fetch_log_types(%Session{config: %Config{protocol: :w3c}} = session) do
    case W3CWireProtocolClient.fetch_log_types(session) do
      {:ok, log_types} ->
        {:ok, log_types}

      {:error, error} ->
        {:error, to_error(error)}
    end
  end

  @doc """
  Fetches log entries for the requested log type.
  """
  doc_metadata subject: :logging
  @spec fetch_logs(Session.t(), log_type) :: {:ok, [LogEntry.t()]} | {:error, basic_reason()}
  def fetch_logs(session, log_type)

  def fetch_logs(%Session{config: %Config{protocol: :jwp}} = session, log_type)
      when is_binary(log_type) do
    case JSONWireProtocolClient.fetch_logs(session, log_type) do
      {:ok, log_entries} ->
        log_entries = Enum.map(log_entries, &to_log_entry/1)
        {:ok, log_entries}

      {:error, error} ->
        {:error, to_error(error)}
    end
  end

  def fetch_logs(%Session{config: %Config{protocol: :w3c}} = session, log_type)
      when is_binary(log_type) do
    case W3CWireProtocolClient.fetch_logs(session, log_type) do
      {:ok, log_entries} ->
        log_entries = Enum.map(log_entries, &to_log_entry/1)
        {:ok, log_entries}

      {:error, error} ->
        {:error, to_error(error)}
    end
  end

  @spec to_log_entry(JSONWireProtocolClient.LogEntry.t()) :: LogEntry.t()
  defp to_log_entry(%JSONWireProtocolClient.LogEntry{} = log_entry) do
    log_entry
    |> Map.from_struct()
    |> (&struct!(LogEntry, &1)).()
  end

  @spec to_log_entry(W3CWireProtocolClient.LogEntry.t()) :: LogEntry.t()
  defp to_log_entry(%W3CWireProtocolClient.LogEntry{} = log_entry) do
    log_entry
    |> Map.from_struct()
    |> (&struct!(LogEntry, &1)).()
  end

  defp to_error(%JSONWireProtocolClient.WebDriverError{reason: reason}) do
    WebDriverError.exception(reason: reason)
  end

  defp to_error(%W3CWireProtocolClient.WebDriverError{reason: reason}) do
    WebDriverError.exception(reason: reason)
  end

  defp to_error(%HTTPClientError{} = error), do: error

  defp to_error(%W3CWireProtocolClient.UnexpectedResponseError{
         reason: reason,
         response_body: response_body
       }) do
    UnexpectedResponseError.exception(
      reason: reason,
      response_body: response_body,
      protocol: :w3c
    )
  end

  defp to_error(%JSONWireProtocolClient.UnexpectedResponseError{
         reason: reason,
         response_body: response_body
       }) do
    UnexpectedResponseError.exception(
      reason: reason,
      response_body: response_body,
      protocol: :jwp
    )
  end
end
