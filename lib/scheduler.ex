defmodule Scheduler do

  require Integer

  @moduledoc """
  Documentation for Scheduler.
  """


  @doc """
  Generates all legal matchup sets for a week/leg

  A matchup set is a complete set of matchups where all rosters have a matchup.

  If there are any fixed_matchups, those must be included in the set.

  ## Examples

    iex> Scheduler.available_matchup_sets([1, 2])
    [[{1, 2}]]

  """

  def available_matchup_sets(rosters) do
    if Integer.is_odd(Enum.count(rosters)) do
      _available_matchup_sets(["bye" | rosters])
    else
      _available_matchup_sets(rosters)
    end
  end

  # base case is two rosters [a, b], results in only one legal matchup set -> [[{a, b}]]
  def _available_matchup_sets([a, b]) do
    [[{a, b}]]
  end

  def _available_matchup_sets(rosters) do
    matchups = pairs(rosters)

    [first | rest] = matchups

    []
  end

  @doc """

  ## Examples

    iex> Scheduler.pairs([])
    []

    iex> Scheduler.pairs([1])
    []

    iex> Scheduler.pairs([1, 2])
    [{1, 2}]

    iex> Scheduler.pairs([1, 2, 3])
    [{1, 2}, {1, 3}, {2, 3}]

    iex> Scheduler.pairs(["bye", 1, 2, 3])
    [{"bye", 1}, {"bye", 2}, {"bye", 3}, {1, 2}, {1, 3}, {2, 3}]

  """
  def pairs([]) do
    []
  end

  def pairs([_]) do
    []
  end

  def pairs([head | tail]) do
    tail |> Enum.map(fn el -> {head, el} end) |> Enum.concat(pairs(tail))
  end
end
