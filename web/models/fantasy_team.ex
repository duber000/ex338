defmodule Ex338.FantasyTeam do
  @moduledoc false

  use Ex338.Web, :model

  alias Ex338.{FantasyLeague, RosterPosition, TransactionLineItem}

  schema "fantasy_teams" do
    field :team_name, :string
    field :waiver_position, :integer
    belongs_to :fantasy_league, FantasyLeague
    has_many :roster_positions, RosterPosition
    has_many :fantasy_players, through: [:roster_positions, :fantasy_player]
    has_many :transaction_line_items, TransactionLineItem
    has_many :roster_transactions, through: [:transaction_line_items, 
                                             :roster_transaction]

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:team_name, :waiver_position, :fantasy_league_id])
    |> validate_required([:team_name, :waiver_position])
  end

  def by_league(query, league_id) do
    from t in query,
      where: t.fantasy_league_id == ^league_id
  end 

  def alphabetical(query) do
    from t in query, order_by: t.team_name
  end

  def right_join_players_by_league(query, fantasy_league_id) do
    from t in query,
    left_join: r in RosterPosition,
    on: r.fantasy_team_id == t.id and t.fantasy_league_id == ^fantasy_league_id,
    right_join: p in assoc(r, :fantasy_player),
    inner_join: s in assoc(p, :sports_league),
    select: %{team_name: t.team_name, player_name: p.player_name, 
              league_name: s.league_name},
    order_by: [s.league_name, p.player_name]
  end
end
