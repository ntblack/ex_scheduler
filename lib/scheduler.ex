defmodule Scheduler do

  require Integer

  @moduledoc """
  Documentation for Scheduler.
  """

  @doc """

  Generates a set of all valid complete schedules for the given rosters. Each schedule consists
  of a list of weekly matchup sets. The number of weeks in the schedule depends on the number of
  rosters but is equal to n = Enum.count(rosters) if n is odd or n - 1 if rosters is even. If n is odd,
  each week will contain a bye.

  ## Examples

    iex> Scheduler.valid_schedules([1, 2])
    [[{1, 2}]]

    iex> Scheduler.valid_schedules([1, 2, 3])
    [[{"bye", 1}, {2, 3}], [{"bye", 2}, {1, 3}], [{"bye", 3}, {1, 2}]]

  """
  def valid_schedules(rosters) do
    possible_weeks = available_matchup_sets(rosters)

    _valid_schedules(MapSet.new(), possible_weeks)
  end

  def _valid_schedules(_, []) do
    []
  end

  def _valid_schedules(matchups_used, [week | other_possible_weeks]) do
    next_matchups_used = MapSet.new(week) |> MapSet.union(matchups_used)

    valid_weeks_remaining = other_possible_weeks |> Enum.reject(fn other_week ->
      Enum.any?(other_week, fn matchup ->
        MapSet.member?(next_matchups_used, matchup)
      end)
    end)


    # TODO: this is only one schedule, but there are other valid ones
    [week | _valid_schedules(next_matchups_used, valid_weeks_remaining)]

  end

  @doc """
  Generates all legal matchup sets for a week/leg
  A matchup set is a complete week of matchups where all rosters have a matchup.

  ## Examples

    iex> Scheduler.available_matchup_sets([1, 2])
    [[{1, 2}]]

    iex> Scheduler.available_matchup_sets([1, 2, 3, 4])
    [[{1, 2}, {3, 4}], [{1, 3}, {2, 4}], [{1, 4}, {2, 3}]]

    iex> Scheduler.available_matchup_sets([1, 2, 3])
    [[{"bye", 1}, {2, 3}], [{"bye", 2}, {1, 3}], [{"bye", 3}, {1, 2}]]

    iex> Scheduler.available_matchup_sets([1, 2, 3, 4, 5]) |> Enum.at(0)
    [{"bye", 1}, {2, 3}, {4, 5}]

    iex> Scheduler.available_matchup_sets([1, 2, 3, 4, 5]) |> Enum.at(1)
    [{"bye", 1}, {2, 4}, {3, 5}]

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

    matchups |> Enum.flat_map(fn {a, b} ->
      remaining_rosters = rosters |> Enum.reject(fn num ->  num == a || num == b end)
      subsets = _available_matchup_sets(remaining_rosters)
      subsets |> Enum.map(fn item -> [{a, b} | item] end)
    end)

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
    [{1, 2}, {1, 3}]

    iex> Scheduler.pairs(["bye", 1, 2, 3])
    [{"bye", 1}, {"bye", 2}, {"bye", 3}]

  """
  def pairs([]) do
    []
  end

  def pairs([_]) do
    []
  end

  def pairs([head | tail]) do
    tail |> Enum.map(fn el -> {head, el} end)
  end
end
