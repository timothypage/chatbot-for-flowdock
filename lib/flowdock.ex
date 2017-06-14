defmodule Flowdock do
  @moduledoc """
  Documentation for Flowdock.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Flowdock.hello
      :world

  """
  @api_endpoint "api.flowdock.com"
  @stream_endpoint "stream.flowdock.com"

  @flow Application.get_env(:flowdock, :flow)

  def hello do
    :world
  end

  def headers do
    encoded_token = Base.encode64( Application.get_env(:flowdock, :api_key) <> ":" )
    ["Authorization": "Basic #{encoded_token}", "Content-Type": "application/json", "Accept": "application/json"]
  end

  def list_flows do
    %HTTPoison.Response{body: body, headers: _} = HTTPoison.get!("https://" <> @api_endpoint <> "/flows", headers())
    flows = Poison.decode!(body)
    flows
  end

  def connect do
    {:ok, conn} = :gun.open(to_char_list(@stream_endpoint), 443)

    encoded_token = Base.encode64( Application.get_env(:flowdock, :api_key) <> ":" )
    gun_headers = [{"authorization", "Basic #{encoded_token}"}, {"connection", "keep-alive"}]

    ref = :gun.get(conn, to_char_list("/flows/#{@flow}"), gun_headers)
    receive do
      {:gun_response, _conn, _stream_ref, :fin, _status, _headers} ->
        :no_data
      {:gun_response, conn, stream_ref, :nofin, _status, _headers} ->
        receive_data(conn, ref, stream_ref)
    end
  end

  def process_message({:error, _, _}) do
    IO.puts "nothing to see here..."
  end

  def process_message({:ok, %{"content" => %{"typing" => _who_is_typing}}}) do
    IO.puts "someone is typing"
  end

  def process_message({:ok, %{"content" => content}}) do
    IO.puts "Someone said: " <> content
  end

  def receive_data(_conn, ref, _stream_ref) do
    receive do
      {:gun_data, conn, stream_ref, :nofin, data} -> 
        process_message(Poison.decode(data))
        receive_data(conn, ref, stream_ref)
      {:gun_data, _conn, _stream_ref, :fin, data} ->
        IO.puts inspect(data)
      {"DOWN", _ref, :process, _conn, reason} ->
        IO.puts "Error!"
        exit(reason)
    end
  end

  def post_message(message) do
    message_body = %{
      event: "message",
      content: message
    }

    send_body = Poison.encode!(message_body)

    HTTPoison.post!("https://" <> @api_endpoint <> "/flows/#{@flow}/messages", send_body, headers())
  end



end
