defmodule Ex338.RosterPosition.StoreTest do
  use Ex338.ModelCase
  alias Ex338.{RosterPosition.Store}

  describe "positions_for_draft/2" do
    test "returns all positions for a championship in a league" do
      league = insert(:fantasy_league)
      other_league = insert(:fantasy_league)
      team_a = insert(:fantasy_team, fantasy_league: league)
      team_b = insert(:fantasy_team, fantasy_league: other_league)

      sport = insert(:sports_league)
      other_sport = insert(:sports_league)
      championship =
        insert(:championship, category: "overall", sports_league: sport)

      player_1 =
        insert(:fantasy_player, sports_league: sport, draft_pick: true)
      player_2 =
        insert(:fantasy_player, sports_league: other_sport, draft_pick: true)
      player_3 =
        insert(:fantasy_player, sports_league: sport, draft_pick: false)
      player_4 =
        insert(:fantasy_player, sports_league: sport, draft_pick: true)

      pos =
        insert(:roster_position, fantasy_player: player_1, fantasy_team: team_a,
          status: "active")
      insert(:roster_position, fantasy_player: player_1, fantasy_team: team_b)
      insert(:roster_position, fantasy_player: player_2, fantasy_team: team_a)
      insert(:roster_position, fantasy_player: player_3, fantasy_team: team_a)
      insert(:roster_position, fantasy_player: player_4, fantasy_team: team_a,
        status: "traded")

      [result] = Store.positions_for_draft(league.id, championship.id)

      assert result.id == pos.id
      assert result.fantasy_player.player_name == player_1.player_name
    end
  end

  describe "positions/1" do
    test "returns all primary & flex positions for a league" do
      sport_b = insert(:sports_league, abbrev: "b")
      sport_c = insert(:sports_league, abbrev: "c")
      sport_a = insert(:sports_league, abbrev: "a")
      insert(:sports_league, abbrev: "z")

      league = insert(:fantasy_league)

      insert(:league_sport, fantasy_league: league, sports_league: sport_a)
      insert(:league_sport, fantasy_league: league, sports_league: sport_b)
      insert(:league_sport, fantasy_league: league, sports_league: sport_c)

      result = Store.positions(league.id)

      assert Enum.count(result) == 9
      assert Enum.any?(result, &(&1 == sport_a.abbrev))
      assert Enum.any?(result, &(&1 == "Flex1"))
    end
  end

  describe "all_positions/1" do
    test "returns all positions for a league" do
      sport_b = insert(:sports_league, abbrev: "b")
      sport_c = insert(:sports_league, abbrev: "c")
      sport_a = insert(:sports_league, abbrev: "a")
      insert(:sports_league, abbrev: "z")

      league = insert(:fantasy_league)

      insert(:league_sport, fantasy_league: league, sports_league: sport_a)
      insert(:league_sport, fantasy_league: league, sports_league: sport_b)
      insert(:league_sport, fantasy_league: league, sports_league: sport_c)

      result = Store.all_positions(league.id)

      assert Enum.count(result) == 10
      assert Enum.any?(result, &(&1 == sport_a.abbrev))
      assert Enum.any?(result, &(&1 == "Flex1"))
      assert Enum.any?(result, &(&1 == "Unassigned"))
    end
  end

  describe "all_positions/0" do
    test "returns all positions" do
      sport_b = insert(:sports_league, abbrev: "b")
      sport_c = insert(:sports_league, abbrev: "c")
      sport_a = insert(:sports_league, abbrev: "a")
      sport_z = insert(:sports_league, abbrev: "z")

      league = insert(:fantasy_league)

      insert(:league_sport, fantasy_league: league, sports_league: sport_a)
      insert(:league_sport, fantasy_league: league, sports_league: sport_b)
      insert(:league_sport, fantasy_league: league, sports_league: sport_c)

      result = Store.all_positions()

      assert Enum.count(result) == 11
      assert Enum.any?(result, &(&1 == sport_a.abbrev))
      assert Enum.any?(result, &(&1 == sport_z.abbrev))
      assert Enum.any?(result, &(&1 == "Flex1"))
      assert Enum.any?(result, &(&1 == "Unassigned"))
    end
  end
end
