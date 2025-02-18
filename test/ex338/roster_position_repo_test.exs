defmodule Ex338.RosterPositionRepoTest do
  use Ex338.DataCase
  alias Ex338.{RosterPosition}

  describe "active_by_sports_league/2" do
    test "only returns active roster positions from a sport" do
      league = insert(:sports_league)
      other_league = insert(:sports_league)
      player_a = insert(:fantasy_player, sports_league: league)
      player_b = insert(:fantasy_player, sports_league: other_league)
      player_c = insert(:fantasy_player, sports_league: league)
      pos = insert(:roster_position, fantasy_player: player_a, status: "active")
      insert(:roster_position, fantasy_player: player_b, status: "active")
      insert(:roster_position, fantasy_player: player_c, status: "traded")

      result =
        RosterPosition
        |> RosterPosition.active_by_sports_league(league.id)
        |> Repo.one()

      assert result.id == pos.id
    end
  end

  describe "all_active/1" do
    test "only returns active roster positions" do
      league = insert(:sports_league)
      player_a = insert(:fantasy_player, sports_league: league)
      player_b = insert(:fantasy_player, sports_league: league)
      pos = insert(:roster_position, fantasy_player: player_a, status: "active")
      insert(:roster_position, fantasy_player: player_b, status: "traded")

      result =
        RosterPosition
        |> RosterPosition.all_active()
        |> Repo.one()

      assert result.id == pos.id
    end
  end

  describe "all_draft_picks/1" do
    test "returns all positions where draft pick is true" do
      pick = insert(:fantasy_player, draft_pick: true)
      player = insert(:fantasy_player, draft_pick: false)
      pos = insert(:roster_position, fantasy_player: pick)
      insert(:roster_position, fantasy_player: player)

      result =
        RosterPosition
        |> RosterPosition.all_draft_picks()
        |> Repo.one()

      assert result.id == pos.id
    end
  end

  describe "all_owned/1" do
    test "only returns owned roster positions" do
      sport = insert(:sports_league)
      player_a = insert(:fantasy_player, sports_league: sport)
      player_b = insert(:fantasy_player, sports_league: sport)
      player_c = insert(:fantasy_player, sports_league: sport)
      ir_pos = insert(:roster_position, fantasy_player: player_a, status: "injured_reserve")
      active_pos = insert(:roster_position, fantasy_player: player_b, status: "active")
      insert(:roster_position, fantasy_player: player_c, status: "dropped")

      result =
        RosterPosition
        |> RosterPosition.all_owned()
        |> Repo.all()
        |> Enum.map(& &1.id)

      assert result == [ir_pos.id, active_pos.id]
    end
  end

  describe "all_owned_from_league/2" do
    test "only returns owned roster positions from a league" do
      league = insert(:fantasy_league)
      team = insert(:fantasy_team, fantasy_league: league)
      other_league = insert(:fantasy_league)
      other_team = insert(:fantasy_team, fantasy_league: other_league)
      sport = insert(:sports_league)
      player_a = insert(:fantasy_player, sports_league: sport)
      player_b = insert(:fantasy_player, sports_league: sport)
      player_c = insert(:fantasy_player, sports_league: sport)

      pos =
        insert(:roster_position, fantasy_team: team, fantasy_player: player_a, status: "active")

      insert(:roster_position, fantasy_team: team, fantasy_player: player_b, status: "dropped")

      insert(
        :roster_position,
        fantasy_team: other_team,
        fantasy_player: player_c,
        status: "active"
      )

      result =
        RosterPosition
        |> RosterPosition.all_owned_from_league(league.id)
        |> Repo.one()

      assert result.id == pos.id
    end
  end

  describe "by_league/2" do
    test "returns roster positions for a given league with teams preloaded" do
      league = insert(:fantasy_league)
      other_league = insert(:fantasy_league)
      team = insert(:fantasy_team, fantasy_league: league)
      other_team = insert(:fantasy_team, fantasy_league: other_league)
      insert(:roster_position, fantasy_team: team, status: "active")
      insert(:roster_position, fantasy_team: other_team, status: "active")

      [result] =
        RosterPosition
        |> RosterPosition.by_league(league.id)
        |> Repo.all()

      assert result.fantasy_team.id == team.id
    end
  end

  describe "count_positions_for_team" do
    test "counts the active positions on a fantasy team" do
      team = insert(:fantasy_team)
      insert_list(2, :roster_position, fantasy_team: team, status: "active")

      count = RosterPosition.count_positions_for_team(RosterPosition, team.id)

      assert count == 2
    end
  end

  describe "from_league/2" do
    test "returns roster positions for a given league with teams preloaded" do
      league = insert(:fantasy_league)
      other_league = insert(:fantasy_league)
      team = insert(:fantasy_team, fantasy_league: league)
      other_team = insert(:fantasy_team, fantasy_league: other_league)
      pos = insert(:roster_position, fantasy_team: team)
      insert(:roster_position, fantasy_team: other_team)

      [result] =
        RosterPosition
        |> RosterPosition.from_league(league.id)
        |> Repo.all()

      assert result.id == pos.id
    end
  end

  describe "order_by_id/1" do
    test "orders roster positions by id" do
      pos_a = insert(:roster_position)
      pos_b = insert(:roster_position)

      result =
        RosterPosition
        |> RosterPosition.order_by_id()
        |> Repo.all()

      assert Enum.map(result, & &1.id) == Enum.sort([pos_a.id, pos_b.id])
    end
  end

  describe "preload_assocs/1" do
    test "preloads assocs for RosterPosition struct" do
      player = insert(:fantasy_player)
      team = insert(:fantasy_team)
      insert(:roster_position, fantasy_team: team, fantasy_player: player)

      result =
        RosterPosition
        |> RosterPosition.preload_assocs()
        |> Repo.one()

      assert result.fantasy_team.id == team.id
      assert result.fantasy_player.id == player.id
      assert result.championship_slots == []
      assert result.in_season_draft_picks == []
    end
  end

  describe "sport_from_champ/2" do
    test "returns positions for a sport from a championship" do
      sport = insert(:sports_league)
      championship = insert(:championship, sports_league: sport)
      other_sport = insert(:sports_league)
      player_a = insert(:fantasy_player, sports_league: sport)
      player_b = insert(:fantasy_player, sports_league: other_sport)
      pos = insert(:roster_position, fantasy_player: player_a)
      insert(:roster_position, fantasy_player: player_b)

      result =
        RosterPosition
        |> RosterPosition.sport_from_champ(championship.id)
        |> Repo.one()

      assert result.id == pos.id
    end
  end

  describe "update_dropped_player/5" do
    test "updates roster position by team and player ids" do
      team = insert(:fantasy_team)
      player = insert(:fantasy_player)

      position =
        insert(
          :roster_position,
          fantasy_player: player,
          fantasy_team: team,
          status: "active",
          released_at: nil
        )

      released_at = DateTime.utc_now()
      status = "dropped"

      RosterPosition
      |> RosterPosition.update_position_status(team.id, player.id, released_at, status)
      |> Repo.update_all([])

      result = Repo.get!(RosterPosition, position.id)

      assert result.status == "dropped"
      assert DateTime.diff(result.released_at, DateTime.utc_now()) < 1
    end
  end
end
