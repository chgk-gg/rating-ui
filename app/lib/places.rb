module Places
  def self.add_top_and_bottom_places!(teams)
    grouped_by_place = teams.each_with_object(Hash.new { |h, k| h[k] = [] }) do |team, hash|
      hash[team["place"]] << team
    end

    grouped_by_place.each do |place, tied_teams|
      tied_teams.each do |team|
        team["top_place"] = place
        team["bottom_place"] = place + tied_teams.size - 1
      end
    end
  end

  def self.add_previous_top_and_bottom_places!(teams)
    grouped_by_place = teams.each_with_object(Hash.new { |h, k| h[k] = [] }) do |team, hash|
      hash[team["previous_place"]] << team
    end

    grouped_by_place.each do |place, tied_teams|
      tied_teams.each do |team|
        team["previous_top_place"] = place
        team["previous_bottom_place"] = if place.nil?
          nil
        else
          place + tied_teams.size - 1
        end
      end
    end
  end
end
