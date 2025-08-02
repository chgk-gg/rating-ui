# frozen_string_literal: true

require "test_helper"

class RosterContinuityTest < ActiveSupport::TestCase
  attr_reader :date

  def setup
    @date = Date.new(2025, 8, 1)
    @old_date = Date.new(2021, 12, 16)
  end

  def test_has_continuity_zero_legionnaires
    (1..2).each do |base_count|
      assert_not RosterContinuity.counts_are_high_enough?(base_players_count: base_count, legionnaires_count: 0, date:)
    end
    (3..7).each do |base_count|
      assert RosterContinuity.counts_are_high_enough?(base_players_count: base_count, legionnaires_count: 0, date:)
    end
  end

  def test_has_continuity_one_legionnaire
    (1..2).each do |base_count|
      assert_not RosterContinuity.counts_are_high_enough?(base_players_count: base_count, legionnaires_count: 1, date:)
    end
    (3..7).each do |base_count|
      assert RosterContinuity.counts_are_high_enough?(base_players_count: base_count, legionnaires_count: 1, date:)
    end
  end

  def test_has_continuity_two_legionnaires
    (1..2).each do |base_count|
      assert_not RosterContinuity.counts_are_high_enough?(base_players_count: base_count, legionnaires_count: 2, date:)
    end
    (3..7).each do |base_count|
      assert RosterContinuity.counts_are_high_enough?(base_players_count: base_count, legionnaires_count: 2, date:)
    end
  end

  def test_has_continuity_three_legionnaires
    (1..3).each do |base_count|
      assert_not RosterContinuity.counts_are_high_enough?(base_players_count: base_count, legionnaires_count: 3, date:)
    end
    (4..7).each do |base_count|
      assert RosterContinuity.counts_are_high_enough?(base_players_count: base_count, legionnaires_count: 3, date:)
    end
  end

  def test_has_continuity_more_legionnaires
    (4..7).each do |legionnaires_count|
      (1..7).each do |base_players_count|
        assert_not RosterContinuity.counts_are_high_enough?(base_players_count:, legionnaires_count:, date:)
      end
    end
  end

  def test_old_rules
    6.times do |legionnaires_count|
      (1..3).each do |base_players_count|
        assert_not RosterContinuity.counts_are_high_enough?(base_players_count:, legionnaires_count:, date: @old_date)
      end
    end

    6.times do |legionnaires_count|
      (4..8).each do |base_players_count|
        assert RosterContinuity.counts_are_high_enough?(base_players_count:, legionnaires_count:, date: @old_date)
      end
    end
  end
end
