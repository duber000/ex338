defmodule Ex338.DraftPick.StoreTest do
  use Ex338.DataCase

  alias Ex338.{DraftPick.Store}

  describe "draft_player/2" do
    test "updates draft pick and inserts new roster position" do
      league = insert(:fantasy_league)
      team = insert(:fantasy_team, fantasy_league: league)
      pick = insert(:draft_pick, fantasy_league: league, fantasy_team: team)
      player = insert(:fantasy_player)
      params = %{"fantasy_player_id" => player.id}

      {:ok, %{draft_pick: draft_pick, roster_position: position}} =
        Store.draft_player(pick, params)

      assert draft_pick.fantasy_player_id == player.id
      refute draft_pick.drafted_at == nil
      assert position.fantasy_team_id == team.id
      assert position.fantasy_player_id == player.id
    end

    test "updates pending draft queues to unavailable or drafted" do
      league = insert(:fantasy_league)
      team = insert(:fantasy_team, fantasy_league: league)
      pick = insert(:draft_pick, fantasy_league: league, fantasy_team: team)
      player = insert(:fantasy_player)
      params = %{"fantasy_player_id" => player.id}

      team2 = insert(:fantasy_team, fantasy_league: league)

      _drafted =
        insert(
          :draft_queue,
          fantasy_team: team,
          fantasy_player: player,
          status: :pending
        )

      _unavailable =
        insert(
          :draft_queue,
          fantasy_team: team2,
          fantasy_player: player,
          status: :pending
        )

      {
        :ok,
        %{
          unavailable_draft_queues: {1, [unavailable_queue]},
          drafted_draft_queues: {1, [drafted_queue]}
        }
      } = Store.draft_player(pick, params)

      assert unavailable_queue.status == :unavailable
      assert drafted_queue.status == :drafted
    end

    test "does not update draft pick and returns error with invalid params" do
      league = insert(:fantasy_league)
      team = insert(:fantasy_team, fantasy_league: league)
      pick = insert(:draft_pick, fantasy_league: league, fantasy_team: team)
      params = %{"fantasy_player_id" => ""}

      {:error, :draft_pick, draft_pick_changeset, %{}} = Store.draft_player(pick, params)

      refute draft_pick_changeset.valid?
    end
  end

  describe "get_last_picks/1" do
    test "by default returns last 5 picks in descending order" do
      league = insert(:fantasy_league)
      insert(:submitted_pick, draft_position: 1.04, fantasy_league: league)
      insert(:submitted_pick, draft_position: 1.05, fantasy_league: league)
      insert(:submitted_pick, draft_position: 1.10, fantasy_league: league)
      insert(:submitted_pick, draft_position: 1.15, fantasy_league: league)
      insert(:submitted_pick, draft_position: 1.24, fantasy_league: league)
      insert(:draft_pick, draft_position: 1.30, fantasy_league: league)

      results = Store.get_last_picks(league.id)

      assert Enum.map(results, & &1.draft_position) == [
               1.24,
               1.15,
               1.1,
               1.05,
               1.04
             ]
    end

    test "returns last X picks in descending order" do
      num_picks = 3
      league = insert(:fantasy_league)
      insert(:submitted_pick, draft_position: 1.04, fantasy_league: league)
      insert(:submitted_pick, draft_position: 1.05, fantasy_league: league)
      insert(:submitted_pick, draft_position: 1.10, fantasy_league: league)
      insert(:submitted_pick, draft_position: 1.15, fantasy_league: league)
      insert(:submitted_pick, draft_position: 1.24, fantasy_league: league)
      insert(:draft_pick, draft_position: 1.30, fantasy_league: league)

      results = Store.get_last_picks(league.id, num_picks)

      assert Enum.map(results, & &1.draft_position) == [
               1.24,
               1.15,
               1.1
             ]
    end
  end

  describe "get_next_picks/1" do
    test "by default returns next 5 picks in descending order" do
      league = insert(:fantasy_league)
      team = insert(:fantasy_team)
      player = insert(:fantasy_player)

      insert(
        :draft_pick,
        draft_position: 1.04,
        fantasy_league: league,
        fantasy_team: team,
        fantasy_player: player
      )

      insert(:draft_pick, draft_position: 1.05, fantasy_league: league)
      insert(:draft_pick, draft_position: 1.10, fantasy_league: league)
      insert(:draft_pick, draft_position: 1.15, fantasy_league: league)
      insert(:draft_pick, draft_position: 1.24, fantasy_league: league)
      insert(:draft_pick, draft_position: 1.30, fantasy_league: league)

      results = Store.get_next_picks(league.id)

      assert Enum.map(results, & &1.draft_position) == [
               1.05,
               1.1,
               1.15,
               1.24,
               1.3
             ]
    end

    test "returns next X picks in descending order" do
      num_picks = 3
      league = insert(:fantasy_league)
      team = insert(:fantasy_team)
      player = insert(:fantasy_player)

      insert(
        :draft_pick,
        draft_position: 1.04,
        fantasy_league: league,
        fantasy_team: team,
        fantasy_player: player
      )

      insert(:draft_pick, draft_position: 1.05, fantasy_league: league)
      insert(:draft_pick, draft_position: 1.10, fantasy_league: league)
      insert(:draft_pick, draft_position: 1.15, fantasy_league: league)
      insert(:draft_pick, draft_position: 1.24, fantasy_league: league)
      insert(:draft_pick, draft_position: 1.30, fantasy_league: league)

      results = Store.get_next_picks(league.id, num_picks)

      assert Enum.map(results, & &1.draft_position) == [
               1.05,
               1.1,
               1.15
             ]
    end
  end

  describe "get_picks_for_league/1" do
    test "returns draft picks in descending order" do
      league = insert(:fantasy_league)

      insert(:submitted_pick,
        draft_position: 1.05,
        fantasy_league: league,
        drafted_at: DateTime.from_naive!(~N[2018-09-21 01:30:02.857392], "Etc/UTC")
      )

      insert(:submitted_pick,
        draft_position: 1.04,
        fantasy_league: league,
        drafted_at: DateTime.from_naive!(~N[2018-09-21 01:00:02.857392], "Etc/UTC")
      )

      insert(:draft_pick,
        draft_position: 1.10,
        fantasy_league: league,
        drafted_at: nil
      )

      other_league = insert(:fantasy_league)
      insert(:draft_pick, draft_position: 1.02, fantasy_league: other_league)

      %{draft_picks: picks, fantasy_teams: teams} = Store.get_picks_for_league(league.id)
      [first_pick | _] = picks

      assert Enum.map(picks, & &1.draft_position) == [1.04, 1.05, 1.1]
      assert first_pick.fantasy_league.id == league.id
      assert Enum.map(teams, & &1.avg_seconds_on_the_clock) == [0, 0, 1800]
    end
  end
end
