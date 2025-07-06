# frozen_string_literal: true

module TournamentsHelper
  def tournaments_link_to_page(page:, tournaments_per_page:)
    top_place = (tournaments_per_page * (page - 1)) + 1
    bottom_place = page * tournaments_per_page
    link_to(page, tournaments_path(from: top_place, to: bottom_place))
  end

  def tournaments_link_to_previous_page(current_top:, current_bottom:)
    tournaments_per_page = current_bottom - current_top + 1
    top_place = [current_top - tournaments_per_page, 1].max
    bottom_place = [current_bottom - tournaments_per_page, tournaments_per_page].max
    link_to("←", tournaments_path(from: top_place, to: bottom_place))
  end

  def tournaments_link_to_next_page(current_top:, current_bottom:)
    tournaments_per_page = current_bottom - current_top + 1
    top_place = current_top + tournaments_per_page
    bottom_place = current_bottom + tournaments_per_page
    link_to("→", tournaments_path(from: top_place, to: bottom_place))
  end
end
