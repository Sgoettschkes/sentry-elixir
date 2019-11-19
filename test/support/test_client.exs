defmodule Sentry.TestClient do
  @behaviour Sentry.HTTPClient
  require Logger

  def send_event(%Sentry.Event{} = event, _opts \\ []) do
    {endpoint, _public_key, _secret_key} = Sentry.Client.get_dsn()
    event = Sentry.Client.maybe_call_before_send_event(event)

    Sentry.Client.render_event(event)
    |> Jason.encode()
    |> case do
      {:ok, body} ->
        case Sentry.Client.request(endpoint, [], body) do
          {:ok, id} ->
            {:ok, id}

          {:error, error} ->
            Logger.log(
              Sentry.Config.log_level(),
              fn ->
                [
                  "Failed to send Sentry event.",
                  ?\n,
                  "Event ID: #{event.event_id} - #{inspect(error)} - #{body}"
                ]
              end
            )

            {:error, error}
        end

      {:error, error} ->
        Logger.log(
          Sentry.Config.log_level(),
          "Error sending in Sentry.TestClient: #{inspect(error)}"
        )

        {:error, error}
    end
  end
end
