defmodule WebDriverClient.W3CWireProtocolClient.ResponseParserTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias WebDriverClient.UnexpectedResponseFormatError
  alias WebDriverClient.W3CWireProtocolClient.LogEntry
  alias WebDriverClient.W3CWireProtocolClient.Rect
  alias WebDriverClient.W3CWireProtocolClient.ResponseParser
  alias WebDriverClient.W3CWireProtocolClient.TestResponses

  property "parse_value/1 returns {:ok, url} when result is a string" do
    check all value <-
                one_of([
                  integer(),
                  list_of(url(), max_length: 3),
                  map_of(
                    string(:alphanumeric, max_length: 10),
                    string(:alphanumeric, max_length: 10),
                    max_length: 3
                  )
                ]) do
      response = %{"value" => value}

      assert {:ok, ^value} = ResponseParser.parse_value(response)
    end
  end

  test "parse_value/1 returns {:error, %UnexpectedResponseFormatError{}} on an invalid response" do
    for response <- [[], %{}] do
      assert {:error, %UnexpectedResponseFormatError{response_body: ^response}} =
               ResponseParser.parse_value(response)
    end
  end

  property "parse_url/1 returns {:ok, url} when result is a string" do
    check all url <- url() do
      response = %{"value" => url}

      assert {:ok, ^url} = ResponseParser.parse_url(response)
    end
  end

  property "parse_url/1 returns {:error, %UnexpectedResponseFormatError{}} on an invalid response" do
    check all response <-
                one_of([
                  constant(%{}),
                  fixed_map(%{
                    "value" =>
                      one_of([
                        integer(),
                        list_of(url(), max_length: 3),
                        map_of(
                          string(:alphanumeric, max_length: 10),
                          string(:alphanumeric, max_length: 10),
                          max_length: 3
                        )
                      ])
                  })
                ]) do
      assert {:error, %UnexpectedResponseFormatError{response_body: ^response}} =
               ResponseParser.parse_url(response)
    end
  end

  property "parse_rect/1 returns {:ok, %Rect{}} on valid response" do
    check all x <- integer(),
              y <- integer(),
              width <- integer(0..1000),
              height <- integer(0..1000) do
      response = %{"value" => %{"x" => x, "y" => y, "width" => width, "height" => height}}

      assert {:ok, %Rect{x: ^x, y: ^y, width: ^width, height: ^height}} =
               ResponseParser.parse_rect(response)
    end
  end

  property "parse_rect/1 returns {:error, %UnexpectedResponseFormatError{}} on an invalid response" do
    check all response <-
                one_of([
                  constant(%{}),
                  fixed_map(%{
                    "value" =>
                      fixed_map(%{
                        "x" => string(:alphanumeric),
                        "y" => string(:alphanumeric),
                        "width" => string(:alphanumeric),
                        "height" => string(:alphanumeric)
                      })
                  })
                ]) do
      assert {:error, %UnexpectedResponseFormatError{response_body: ^response}} =
               ResponseParser.parse_rect(response)
    end
  end

  property "parse_log_entries/1 returns {:ok [%LogEntry{}]} when all log entries are valid" do
    check all unparsed_log_entries <- list_of(TestResponses.log_entry(), max_length: 10) do
      response = %{"value" => unparsed_log_entries}

      expected_log_entries =
        Enum.map(unparsed_log_entries, fn %{
                                            "level" => level,
                                            "message" => message,
                                            "timestamp" => timestamp
                                          } ->
          %LogEntry{
            level: level,
            message: message,
            timestamp: DateTime.from_unix!(timestamp, :millisecond)
          }
        end)

      assert {:ok, ^expected_log_entries} = ResponseParser.parse_log_entries(response)
    end
  end

  property "parse_log_entries/1 returns {:error, %UnexpectedResponseFormatError{}} on an invalid response" do
    check all response <-
                one_of([
                  constant(%{}),
                  fixed_map(%{
                    "value" => log_entries_with_invalid_responses()
                  })
                ]) do
      assert {:error, %UnexpectedResponseFormatError{response_body: ^response}} =
               ResponseParser.parse_log_entries(response)
    end
  end

  defp log_entries_with_invalid_responses do
    gen all valid_log_entries <- list_of(TestResponses.log_entry(), max_length: 10),
            invalid_log_entries <- list_of(constant(%{}), min_length: 1, max_length: 10) do
      [valid_log_entries, invalid_log_entries]
      |> List.flatten()
      |> Enum.shuffle()
    end
  end

  defp url do
    string(:alphanumeric)
  end
end