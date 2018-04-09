defmodule Game.Command.Listen do
  @moduledoc """
  The "listen" command
  """

  use Game.Command

  alias Data.Exit

  commands(["listen"], parse: false)

  @impl Game.Command
  def help(:topic), do: "Listen"
  def help(:short), do: "Listen to your surroundings"

  def help(:full) do
    """
    This will return anything that can be heard from your surroundings including
    the room, it's features, and any NPCs in the room. You can direct your listening
    towards a room's exit and listen in on the adjacent room.

    Listen to the current room:
    [ ] > {command}listen{/command}

    Listen to an adjacent room:
    [ ] > {command}listen north{/command}
    """
  end

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.Listen.parse("listen")
      {}

      iex> Game.Command.Listen.parse("listen north")
      {:north}

      iex> Game.Command.Listen.parse("listen outside")
      {:error, :bad_parse, "listen outside"}

      iex> Game.Command.Listen.parse("unknown")
      {:error, :bad_parse, "unknown"}
  """
  @spec parse(String.t()) :: {any()}
  def parse(command)
  def parse("listen"), do: {}
  def parse("listen " <> direction) do
    case Exit.exit?(direction) do
      true ->
        {String.to_atom(direction)}

      false ->
        {:error, :bad_parse, "listen " <> direction}
    end
  end

  @impl Game.Command
  def run(command, state)

  def run({}, state = %{save: save}) do
    room = @room.look(save.room_id)

    case room_has_noises?(room) do
      true ->
        state.socket |> @socket.echo(Format.listen_room(room))

      false ->
        state.socket |> @socket.echo("Nothing can be heard")
    end
  end

  def run({direction}, state = %{save: save}) do
    room = @room.look(save.room_id)

    with {:ok, room} <- room |> get_exit(direction),
         true <- room_has_noises?(room) do
      state.socket |> @socket.echo(Format.listen_room(room))
    else
      {:error, :not_found} ->
        state.socket |> @socket.echo("There is no exit that direction to listen to.")

      _ ->
        state.socket |> @socket.echo("Nothing can be heard")
    end
  end

  defp room_has_noises?(room) do
    !is_nil(room.listen) || Enum.any?(room.features, &(!is_nil(&1.listen)))
  end

  def get_exit(room, direction) do
    id_key = String.to_atom("#{direction}_id")
    case room |> Exit.exit_to(direction) do
      %{^id_key => room_id} ->
        room = @room.look(room_id)
        {:ok, room}

      _ ->
        {:error, :not_found}
    end
  end
end
