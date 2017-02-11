defmodule Ex338.Championship do
  @moduledoc false
  use Ex338.Web, :model

  alias Ex338.{ChampionshipResult, ChampionshipSlot}

  @categories ["overall", "event"]

  schema "championships" do
    field :title, :string
    field :category, :string
    field :waiver_deadline_at, Ecto.DateTime
    field :trade_deadline_at, Ecto.DateTime
    field :championship_at, Ecto.DateTime
    belongs_to :sports_league, Ex338.SportsLeague
    belongs_to :overall, Ex338.Championship
    has_many :events, Ex338.Championship, foreign_key: :overall_id
    has_many :championship_results, Ex338.ChampionshipResult
    has_many :championship_slots, Ex338.ChampionshipSlot
    has_many :fantasy_players, through: [:championship_results, :fantasy_player]

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(championship_struct, params \\ %{}) do
    championship_struct
    |> cast(params, [:title, :category, :waiver_deadline_at, :trade_deadline_at,
                     :championship_at, :sports_league_id, :overall_id])
    |> validate_required([:title, :category, :waiver_deadline_at,
                          :trade_deadline_at, :championship_at,
                          :sports_league_id])
  end

  def categories, do: @categories

  def all_with_overall_waivers_open(query) do
    from c in query,
      where: c.waiver_deadline_at > ago(0, "second"),
      where: c.category == "overall"
  end

  def earliest_first(query) do
    from c in query,
      order_by: [asc: :championship_at, asc: :category]
  end

  def future_championships(query) do
    from c in query,
      where: c.championship_at > ago(0, "second"),
      order_by: c.championship_at
  end

  def overall_championships(query) do
    from c in query,
      where: c.category == "overall"
  end

  def preload_assocs(query) do
    results =
      ChampionshipResult.preload_assocs_and_order_results(ChampionshipResult)

    from c in query,
     preload: [:sports_league, championship_results: ^results]
  end

  def preload_assocs_by_league(query, league_id) do
    results =
      ChampionshipResult.preload_ordered_assocs_by_league(
        ChampionshipResult, league_id)

    slots =
      ChampionshipSlot.preload_assocs_by_league(ChampionshipSlot, league_id)

    from c in query,
     preload: [:sports_league, championship_slots: ^slots,
               championship_results: ^results]
  end
end
