defmodule Ex338.Trade.Store do
  @moduledoc false

  alias Ex338.{Trade, TradeLineItem, Repo, Trade.Admin, RosterPosition}

  def all_for_league(league_id) do
    Trade
    |> Trade.by_league(league_id)
    |> Trade.preload_assocs()
    |> Trade.newest_first()
    |> Repo.all()
    |> Trade.count_votes()
  end

  def build_new_changeset() do
    Trade.new_changeset(trade_with_line_items())
  end

  def create_trade(attrs) do
    attrs = filter_trade(attrs)

    %Trade{}
    |> Trade.new_changeset(attrs)
    |> Repo.insert()
  end

  def find!(id) do
    Trade
    |> Trade.preload_assocs()
    |> Repo.get!(id)
  end

  def load_line_items(trade) do
    Repo.preload(
      trade,
      trade_line_items: [
        :gaining_team,
        :losing_team,
        [fantasy_player: :sports_league]
      ]
    )
  end

  def process_trade(trade_id, %{"status" => "Approved"} = params) do
    trade = find!(trade_id)

    case get_pos_from_trade(trade) do
      :error ->
        {:error, "One or more positions not found"}

      positions ->
        trade
        |> Admin.process_approved_trade(params, positions)
        |> Repo.transaction()
    end
  end

  ## Helpers

  ## Implementations

  # build_new_changeset

  defp trade_with_line_items() do
    %Trade{
      trade_line_items: [
        %TradeLineItem{},
        %TradeLineItem{},
        %TradeLineItem{},
        %TradeLineItem{},
        %TradeLineItem{},
        %TradeLineItem{}
      ]
    }
  end

  # create_trade

  defp filter_trade(trade) do
    {line_items, trade} = Map.pop(trade, "trade_line_items")

    line_items =
      line_items
      |> Enum.filter(&filter_line_items/1)
      |> Enum.into(%{})

    Map.put(trade, "trade_line_items", line_items)
  end

  def filter_line_items(
        {_,
         %{
           "fantasy_player_id" => nil,
           "gaining_team_id" => nil,
           "losing_team_id" => nil
         }}
      ) do
    false
  end

  def filter_line_items(_), do: true

  # process_trade

  defp get_pos_from_trade(%{trade_line_items: line_items}) do
    positions = Enum.map(line_items, &query_pos_id/1)

    case Enum.any?(positions, &(&1 == nil)) do
      true -> :error
      false -> positions
    end
  end

  defp query_pos_id(item) do
    clause = %{
      fantasy_player_id: item.fantasy_player_id,
      fantasy_team_id: item.losing_team_id,
      status: "active"
    }

    RosterPosition.Store.get_by(clause)
  end
end
