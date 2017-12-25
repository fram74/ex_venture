defmodule Data.NPC do
  @moduledoc """
  NPC Schema
  """

  use Data.Schema

  alias Data.Event
  alias Data.Stats
  alias Data.NPCItem
  alias Data.NPCSpawner

  schema "npcs" do
    field :name, :string
    field :level, :integer, default: 1
    field :experience_points, :integer, default: 0 # given after defeat
    field :stats, Data.Stats
    field :events, {:array, Event}
    field :notes, :string
    field :tags, {:array, :string}, default: []

    field :currency, :integer, default: 0

    has_many :npc_items, NPCItem
    has_many :npc_spawners, NPCSpawner

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :level, :experience_points, :stats, :currency, :notes, :tags, :events])
    |> validate_required([:name, :level, :experience_points, :stats, :currency, :tags, :events])
    |> validate_stats()
    |> Event.validate_events()
  end

  defp validate_stats(changeset) do
    case changeset do
      %{changes: %{stats: stats}} when stats != nil ->
        case Stats.valid_character?(stats) do
          true -> changeset
          false -> add_error(changeset, :stats, "are invalid")
        end
      _ -> changeset
    end
  end
end
