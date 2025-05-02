# frozen_string_literal: true

module ReleaseHelper
  def link_to_page(release_id:, page:, teams_per_page:, team:, city:)
    top_place = (teams_per_page * (page - 1)) + 1
    bottom_place = page * teams_per_page
    link_to(page, release_path(release_id:, from: top_place, to: bottom_place, team:, city:))
  end

  def link_to_last_page(release_id:, teams_in_release:, teams_per_page:, team:, city:)
    top_place = (teams_per_page * (teams_in_release / teams_per_page)) + 1
    bottom_place = top_place + teams_per_page - 1
    link_to((teams_in_release / teams_per_page) + 1,
      release_path(release_id:, from: top_place, to: bottom_place, team:, city:))
  end

  def link_to_previous_page(release_id:, current_top:, current_bottom:, team:, city:)
    teams_per_page = current_bottom - current_top + 1
    top_place = [current_top - teams_per_page, 1].max
    bottom_place = [current_bottom - teams_per_page, teams_per_page].max
    link_to("←", release_path(release_id:, from: top_place, to: bottom_place, team:, city:))
  end

  def link_to_next_page(release_id:, current_top:, current_bottom:, team:, city:)
    teams_per_page = current_bottom - current_top + 1
    top_place = current_top + teams_per_page
    bottom_place = current_bottom + teams_per_page
    link_to("→", release_path(release_id:, from: top_place, to: bottom_place, team:, city:))
  end
end
