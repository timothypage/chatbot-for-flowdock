defmodule Flowdock.Auth do
  def oauth_credentials_as_json do
    oauth_params = %{
      client_id: Application.get_env(:flowdock, :client_id),
      client_secret: Application.get_env(:flowdock, :client_secret),
      code: Application.get_env(:flowdock, :code),
      grant_type: "authorization_code", 
      redirect_uri: "urn:ietf:wg:oauth:2.0:oob"
    }

    {:ok, body} = Poison.encode(oauth_params)
    body
  end

  def get_token do
    headers = ["Content-Type": "application/json", "Accept": "application/json"]

    response = HTTPoison.post!("https://api.flowdock.com/oauth/token", oauth_credentials_as_json(), headers)
    # response = Poison.decode!(body)
    # response
  end
end