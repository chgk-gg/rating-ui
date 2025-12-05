# frozen_string_literal: true

class ReleaseTournamentPresenter
  attr_reader :players
  attr_accessor :rows

  def initialize(release:, tournament: nil, players: nil, rows: 1)
    @release = release
    @tournament = tournament
    @players = players if tournament.present?
    @rows = rows
  end

  def release_id
    @release["id"]
  end

  def release_date
    I18n.l(@release.date.to_date, format: :short)
  end

  def release_place
    @release.place
  end

  def release_rating
    @release.rating
  end

  def release_rating_change
    @release.rating_change
  end

  def tournament_id
    @tournament.presence&.id
  end

  def name
    @tournament.presence&.name
  end

  def date
    I18n.l(@tournament.date.to_date, format: :short) if @tournament.present?
  end

  def team_id
    @tournament.presence&.team_id
  end

  def team_name
    @tournament.presence&.team_name
  end

  def place
    @tournament.presence&.place
  end

  def rating
    @tournament.presence&.rating
  end

  def in_rating
    return false if @tournament.nil?

    @tournament.in_rating
  end

  def rating_change
    return nil if @tournament.nil?

    @tournament.rating_change
  end
end
