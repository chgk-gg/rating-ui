module API
  module V1
    class TeamsController < APIController
      include InModel

      def release
        return render_error_json(error: MISSING_MODEL_ERROR) if current_model.nil?

        @teams = fetch_teams
        Places.add_top_and_bottom_places!(@teams)
        Places.add_previous_top_and_bottom_places!(@teams)
        add_tournaments!

        render_paged_json(metadata: release_metadata, items: @teams, all_items_count: teams_in_release_count)
      end

      def fetch_teams
        if add_names?
          current_model.teams_with_names_for_release_api(release_id:, limit: page_size, offset:)
        else
          current_model.teams_for_release_api(release_id:, limit: page_size, offset:)
        end
      end

      def add_names?
        params[:show_names] == "true"
      end

      def add_tournaments!
        tournaments = current_model.tournaments_in_release_by_team(release_id:)
        @teams.each do |team|
          team["tournaments"] = tournaments.fetch(team["team_id"], [])
        end
      end

      def release_metadata
        {
          model: current_model.name,
          release_id:
        }
      end

      def show
        return render_error_json(error: MISSING_MODEL_ERROR) if current_model.nil?

        @releases = current_model.team_releases(team_id:).map(&:to_h)
        add_tournaments_by_release!

        render_json(metadata: team_metadata, items: @releases)
      end

      def add_tournaments_by_release!
        tournaments = current_model.team_tournaments(team_id:)

        tournaments_hash = tournaments.each_with_object({}) do |tournament, hash|
          next unless tournament.in_rating

          (hash[tournament["release_id"]] ||= []) << tournament.to_h.except(:release_id)
        end

        @releases.each do |release|
          release["tournaments"] = tournaments_hash[release[:id]]
        end
      end

      def team_metadata
        metadata = {
          model: current_model.name,
          team_id:
        }

        if add_names?
          team = Team.team_details_by_id(team_id)
          metadata[:team_name] = team.name
          metadata[:city] = team.city
        end

        metadata
      end

      private

      def teams_in_release_count
        current_model.count_all_teams_in_release(release_id:)
      end

      def release_id
        @release_id ||= if params[:release_id] == "latest"
          current_model.latest_release_id
        else
          params[:release_id]
        end
      end

      def team_id
        @team_id ||= params[:team_id].to_i
      end
    end
  end
end
