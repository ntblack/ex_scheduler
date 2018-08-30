defmodule Scheduler do

  require Integer


  @doc """

  Generates a schedule for a list of divisions

    iex> Scheduler.schedule_for_divisions([[1, 2], [3, 4]])
    [
      [{1, 2}, {3, 4}],
      [{1, 3}, {2, 4}],
      [{1, 4}, {2, 3}]
    ]

    iex> Scheduler.schedule_for_divisions([[1, 2], [3, 4], [5, 6]])
    [
      [{1, 2}, {3, 4}, {5, 6}],
      [{1, 3}, {2, 5}, {4, 6}],
      [{1, 4}, {2, 6}, {3, 5}],
      [{1, 5}, {2, 4}, {3, 6}],
      [{1, 6}, {2, 3}, {4, 5}]
    ]

    iex> Scheduler.schedule_for_divisions([[1, 2, 3, 4], [5, 6, 7, 8]])
    [
      [{1, 2}, {3, 4}, {5, 6}, {7, 8}],
      [{1, 3}, {2, 4}, {5, 7}, {6, 8}],
      [{1, 4}, {2, 3}, {5, 8}, {6, 7}],
      [{1, 5}, {2, 6}, {3, 7}, {4, 8}],
      [{1, 6}, {2, 5}, {3, 8}, {4, 7}],
      [{1, 7}, {2, 8}, {3, 5}, {4, 6}],
      [{1, 8}, {2, 7}, {3, 6}, {4, 5}]
    ]

    # test cycling the weeks
    iex> Scheduler.schedule_for_divisions([[1, 2], [3, 4], [5, 6]], 17) |> Enum.at(5)
    [{1, 2}, {3, 4}, {5, 6}]


    # test smooshing byes
    iex> Scheduler.schedule_for_divisions([[1, 2, 3], [4, 5, 6]]) |> Enum.at(0) |> MapSet.new
    [{1, 4}, {2, 3}, {5, 6}] |> MapSet.new


  """
  def schedule_for_divisions(divisions, num_weeks \\ nil) do
    division_schedule = divisions |> Enum.map(&valid_schedules/1)
                                  |> Enum.zip
                                  |> Enum.map(&Tuple.to_list/1)
                                  |> Enum.map(&Enum.concat/1)
                                  |> Enum.map(&smoosh_byes/1)

    division_matchups_to_exclude = Enum.concat(division_schedule)
                                   |> MapSet.new

    # for inter-division play, exclude division matchups by putting them in the matchups_used filter
    interdivision_schedule = valid_schedules(Enum.concat(divisions), division_matchups_to_exclude)

    all_weeks = Enum.concat(division_schedule, interdivision_schedule)

    case num_weeks do
      nil -> all_weeks
      _ -> all_weeks |> Stream.cycle |> Enum.take(num_weeks)
    end
  end

  defp smoosh_byes(weekly_matchups) do
    weekly_matchups |> Enum.reduce([], fn matchup, acc ->
      case acc do
        [{"bye", a} | tail] -> case matchup do
                    {"bye", b} -> [{a, b} | tail] # smoosh!
                    _ -> [{"bye", a} | [matchup | tail]] # waiting to smoosh
                 end
       _ -> [matchup | acc]
      end
    end)
    |> Enum.reverse
  end

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
  def valid_schedules(rosters, exclude_matchups \\ MapSet.new()) do
    possible_weeks = available_matchup_sets(rosters)

    _valid_schedules(exclude_matchups, possible_weeks)
  end

  def _valid_schedules(_, []) do
    []
  end

  def _valid_schedules(matchups_used, possible_weeks) do
    valid_weeks = possible_weeks |> Enum.reject(fn week ->
      Enum.any?(week, fn matchup ->
        MapSet.member?(matchups_used, matchup)
      end)
    end)


    case valid_weeks do
      # TODO: this is only one schedule, but there are other valid ones
      [week | remaining_weeks] ->
        [week | _valid_schedules(MapSet.new(week) |> MapSet.union(matchups_used), remaining_weeks)]
      [] -> []
    end

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
