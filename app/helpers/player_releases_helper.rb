# frozen_string_literal: true

module PlayerReleasesHelper
  def link_to_player_release_page(release_id:, page:, players_per_page:, first_name:, last_name:)
    top_place = (players_per_page * (page - 1)) + 1
    bottom_place = page * players_per_page
    link_to(page, player_release_path(release_id:, from: top_place, to: bottom_place, first_name:, last_name:))
  end

  def link_to_last_player_release_page(release_id:, players_in_release:, players_per_page:, first_name:, last_name:)
    top_place = (players_per_page * (players_in_release / players_per_page)) + 1
    bottom_place = top_place + players_per_page - 1
    link_to(players_in_release / players_per_page,
      player_release_path(release_id:, from: top_place, to: bottom_place, first_name:, last_name:))
  end

  def link_to_previous_player_release_page(release_id:, current_top:, current_bottom:, first_name:, last_name:)
    players_per_page = current_bottom - current_top + 1
    top_place = [current_top - players_per_page, 1].max
    bottom_place = [current_bottom - players_per_page, players_per_page].max
    link_to("←", player_release_path(release_id:, from: top_place, to: bottom_place, first_name:, last_name:))
  end

  def link_to_next_player_release_page(release_id:, current_top:, current_bottom:, first_name:, last_name:)
    players_per_page = current_bottom - current_top + 1
    top_place = current_top + players_per_page
    bottom_place = current_bottom + players_per_page
    link_to("→", player_release_path(release_id:, from: top_place, to: bottom_place, first_name:, last_name:))
  end
end
