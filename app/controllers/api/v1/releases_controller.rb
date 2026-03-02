module API
  module V1
    class ReleasesController < APIController
      include InModel

      def index
        return render_error_json(error: MISSING_MODEL_ERROR) if current_model.nil?

        releases = current_model.all_releases
        tournaments = current_model.tournaments_by_release
        releases.each do |release|
          release_tournaments = tournaments[release["id"]]
          grouped = release_tournaments.group_by { |tournament| tournament["in_rating"] == true }

          release["tournaments"] = {
            in_rating: grouped.fetch(true, []).map { |tournament| tournament["id"] },
            not_in_rating: grouped.fetch(false, []).map { |tournament| tournament["id"] }
          }
          release["q"] = Float(release["q"], exception: false)
        end

        render json: metadata.merge({items: releases}), status: :ok
      end

      def metadata
        {
          model: current_model.name
        }
      end
    end
  end
end
