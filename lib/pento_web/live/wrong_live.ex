defmodule PentoWeb.WrongLive do
  use PentoWeb, :live_view

  def mount(_params, session, socket) do
    if connected?(socket) do
      # :timer.send_interval(1, :tick)
      :timer.send_interval(1000, :tick)
    end

    {
      :ok,
      assign(
        socket,
        right_answer: Enum.random(1..10),
        score: 0,
        message: "Guess a number.",
        display_time: time(),
        won_game: nil,
        user: Pento.Accounts.get_user_by_session_token(session["user_token"]),
        session_id: session["live_socket_id"]
      )
    }
  end

  def render(assigns) do
    ~L"""
    <h1>Your score: <%= @score %></h1>
    <p>It's <%= @display_time %></p>
    <h2>
      <p>Welcome, <%= @user.username %>!</p>
      <%= @message %>
      <%= render_button(assigns) %>
    </h2>
    <h2>
      <%= for n <- 1..10 do %>
      <a href="#" phx-click="guess", phx-value-number="<%= n %>"><%= n %></a>
      <% end %>
    </h2>
    <pre>
      <%= @user.email %>
      <%= @session_id %>
    </pre>
    """
  end

  def handle_params(%{ "reset" => "true", "score" => score }=_params, _session, socket) do
    {
      :noreply,
      assign(
        socket,
        right_answer: Enum.random(1..10),
        score: score |> Integer.parse |> elem(0) || 0,
        message: "Guess a number.",
        display_time: time(),
        won_game: nil
      )
    }
  end
  def handle_params(_params, _session, socket), do: {:noreply, socket}

  def handle_info(:tick, socket) do
    {:noreply, assign(socket, display_time: time())}
  end

  def handle_event("guess", %{ "number" => guess }=_data, socket) do
    guess_value = guess |> Integer.parse |> elem(0)
    won_game = guess_value == socket.assigns.right_answer
    message = response_message(guess_value, won_game)
    score = updated_score(socket.assigns.score, won_game)

    {
      :noreply,
      assign(
        socket,
        message: message,
        score: score,
        display_time: time(),
        won_game: won_game
      )
    }
  end

  def updated_score(score, true=_won_game), do: score + 10
  def updated_score(score, _won_game), do: score - 1

  def response_message(guess, true=_won_game), do: "Your guess: #{guess}. Correct! You win!"
  def response_message(guess, false=_won_game), do: "Your guess: #{guess}. Wrong. Guess again."
  def response_message(_guess, nil=_won_game), do: "Guess a number."

  def render_button(assigns) do
    ~L"""
    <%= if @won_game == true do %>
    <p>
      <%= live_patch "Play again?",
            to: Routes.page_path(
              @socket,
              :guess,
              reset: true,
              score: @score
            )
      %>
    </p>
    <% end %>
    """
  end

  def time() do
    DateTime.utc_now |> to_string
  end
end
