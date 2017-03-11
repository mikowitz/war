defmodule Player do
  @moduledoc """
  Models a player using `GenServer`
  """
  use GenServer

  defstruct name: nil

  @spec new(String.t) :: pid
  def new(name) do
    {:ok, player} = GenServer.start_link(__MODULE__, name)
    player
  end

  @doc """
  Return `player`'s name
  """
  @spec name(pid) :: String.t
  def name(player) do
    GenServer.call(player, :name)
  end

  @doc """
  Join `game` as `player`
  """
  @spec join(pid, pid) :: :ok
  def join(player, game) do
    GenStateMachine.cast(game, {:player_joined, player})
  end

  @doc """
  Public API for requesting a single card from `player`
  """
  @spec request_card(pid) :: :ok
  def request_card(player) do
    GenServer.cast(player, :request_card)
  end

  @doc """
  Public API for requesting cards for a war from `player`
  """
  @spec request_war(pid) :: :ok
  def request_war(player) do
    GenServer.cast(player, :request_war)
  end

  @doc """
  Public API for turning over a card in `game`
  """
  @spec give_card(pid, pid) :: :ok
  def give_card(player, game) do
    Game.play_card(game, player)
  end

  @doc """
  Public API for turning over cards for a war in `game`
  """
  @spec give_cards_for_war(pid, pid) :: :ok
  def give_cards_for_war(player, game) do
    Game.play_war(game, player)
  end

  @doc false
  @spec init(String.t) :: {:ok, %Player{}}
  def init(name) do
    {:ok, %__MODULE__{name: name}}
  end

  @doc false
  @spec handle_call(atom, term, Map.t) :: :ok
  def handle_call(_, _, _)

  def handle_call(:name, _from, state) do
    {:reply, state.name, state}
  end

  @doc false
  @spec handle_cast(atom, Map.t) :: :ok
  def handle_cast(_, _)

  def handle_cast(:request_card, state) do
    IO.puts "#{state.name}: we need a card from you."
    {:noreply, state}
  end

  def handle_cast(:request_war, state) do
    IO.puts "#{state.name}: we need 4 cards from you for a war!"
    {:noreply, state}
  end
end
