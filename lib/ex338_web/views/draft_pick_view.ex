defmodule Ex338Web.DraftPickView do
  use Ex338Web, :view

  alias Ex338.DraftPick

  def available_to_pick?(draft_picks, draft_pick) do
    next_pick?(draft_picks, draft_pick) || available_with_skips?(draft_picks, draft_pick)
  end

  def current_picks(draft_picks, amount) when amount >= 0 do
    next_pick_index = Enum.find_index(draft_picks, &(&1.fantasy_player_id == nil))
    get_current_picks(draft_picks, next_pick_index, amount)
  end

  defp get_current_picks(draft_picks, nil, amount) do
    Enum.take(draft_picks, -div(amount, 2))
  end

  defp get_current_picks(draft_picks, index, amount) do
    start_index = index - div(amount, 2)

    start_index =
      if start_index < 0 do
        0
      else
        start_index
      end

    Enum.slice(draft_picks, start_index, amount)
  end

  def seconds_to_hours(seconds) do
    Float.floor(seconds / 3600, 2)
  end

  def seconds_to_mins(seconds) do
    Float.floor(seconds / 60, 2)
  end

  ## Helpers

  ## available_to_pick?

  defp next_pick?(draft_picks, draft_pick) do
    Enum.find(draft_picks, &(&1.fantasy_player_id == nil)) == draft_pick
  end

  defp available_with_skips?(draft_picks, draft_pick) do
    DraftPick.available_with_skipped_picks?(draft_pick.id, draft_picks)
  end
end
