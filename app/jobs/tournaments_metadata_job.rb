# frozen_string_literal: true

class TournamentsMetadataJob < ApplicationJob
  queue_as :chgk_info_import
  limits_concurrency to: 1, key: :chgk_info_api

  attr_reader :category, :api_client

  def perform(category)
    unless %w[all rating recently_updated starting_soon].include?(category)
      raise ArgumentError, "category should be one of all, rating, recently_updated, starting_soon"
    end

    @category = category
    @api_client = ChgkInfo::APIClient.new

    fetch_tournaments_data
  end

  def maybe_update(tournament_hash)
    tournament = Tournament.find_or_initialize_by(id: tournament_hash["id"])
    tournament.assign_attributes(
      title: tournament_hash["name"],
      start_datetime: tournament_hash["dateStart"],
      end_datetime: tournament_hash["dateEnd"],
      last_edited_at: tournament_hash["lastEditDate"],
      questions_count: tournament_hash["questionQty"]&.values&.sum,
      type: tournament_hash.dig("type", "name"),
      typeoft_id: tournament_hash.dig("type", "id"),
      maii_rating: tournament_hash["maiiRating"],
      maii_rating_updated_at: tournament_hash["maiiRatingUpdatedAt"],
      maii_aegis: tournament_hash["maiiAegis"],
      maii_aegis_updated_at: tournament_hash["maiiAegisUpdatedAt"],
      in_old_rating: tournament_hash["tournamentInRatingBalanced"]
    )

    if tournament.changed?
      Rails.logger.info "updating tournament #{tournament.id} (#{tournament.title})"
      tournament.save!
    end
  end

  def fetch_tournaments_data
    page_number = 1
    tournaments = fetch_page(page_number)
    updated_count = 0

    while tournaments.size > 0
      tournaments.each do |tournament|
        next if has_malformed_dates?(tournament)

        updated_count += 1 if maybe_update(tournament)

        save_editors(tournament)
        save_organizers(tournament)
        save_game_jury(tournament)
        save_appeal_jury(tournament)
      end

      Rails.logger.info "processed page #{page_number}. Cumulative update count: #{updated_count}"

      page_number += 1
      tournaments = begin
        fetch_page(page_number)
      rescue => e
        Rails.logger.error "Error fetching page #{page_number}: #{e.message}"
        next
      end
    end
  end

  def has_malformed_dates?(tournament)
    tournament["dateStart"]&.start_with?("-0001") || tournament["dateEnd"]&.start_with?("-0001")
  end

  def fetch_page(page)
    case category
    when "rating"
      api_client.rating_tournaments(page:)
    when "all"
      api_client.all_tournaments(page:)
    when "recently_updated"
      api_client.tournaments_updated_after(date: last_week, page:)
    when "starting_soon"
      api_client.tournaments_starting_between(start_date: Time.zone.today.to_s, end_date: (Time.zone.today + 7).to_s, page:)
    else
      raise ArgumentError
    end
  end

  def last_week
    (Time.zone.today - 7).to_s
  end

  def save_editors(tournament_hash)
    update_helper_table(tournament_hash["id"], tournament_hash["editors"], TournamentEditor)
  end

  def save_organizers(tournament_hash)
    update_helper_table(tournament_hash["id"], tournament_hash["organizers"], TournamentOrganizer)
  end

  def save_game_jury(tournament_hash)
    update_helper_table(tournament_hash["id"], tournament_hash["gameJury"], TournamentGameJury)
  end

  def save_appeal_jury(tournament_hash)
    update_helper_table(tournament_hash["id"], tournament_hash["appealJury"], TournamentAppealJury)
  end

  def update_helper_table(tournament_id, entries, model)
    return unless entries

    data = entries.map { {player_id: it["id"], tournament_id:} }
    model.upsert_all(data, unique_by: %i[tournament_id player_id])
  end
end
