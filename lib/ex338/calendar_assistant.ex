defmodule Ex338.CalendarAssistant do
  @moduledoc """
  Functions to add days to a date
  """

  def days_from_now(days) do
    days = 86_400 * days
    now = DateTime.utc_now()

    Calendar.DateTime.add!(now, days)
  end
end
