# frozen_string_literal: true

module API
  module V1
    class PlayersController < APIController
      include InModel

      def release
        return render_error_json(error: MISSING_MODEL_ERROR) if current_model.nil?

        Rails.logger.info "Fetching players for release #{release_id}, page size #{page_size}, page #{page}"

        @players = fetch_players

        Places.add_top_and_bottom_places!(@players)
        Places.add_previous_top_and_bottom_places!(@players)

        add_rating_components!

        render_paged_json(metadata: release_metadata, items: @players, all_items_count: players_in_release_count)
      end

      def add_names?
        params[:show_names] == "true"
      end

      def fetch_players
        if add_names?
          current_model.players_with_names_for_release_api(release_id:, limit: page_size, offset:)
        else
          current_model.players_for_release_api(release_id:, limit: page_size, offset:)
        end
      end

      def add_rating_components!
        player_ids = @players.map { |player| player["player_id"] }
        tournament_components = current_model.player_ratings_components_for_release(release_id:, player_ids:)
        @players.each do |player|
          player["tournaments"] = tournament_components.fetch(player["player_id"], [])
        end
      end

      def release_metadata
        {
          model: current_model.name,
          release_id:
        }
      end

      def players_in_release_count
        current_model.count_all_players_in_release(release_id:)
      end

      def release_id
        @release_id ||= if params[:release_id] == "latest"
          current_model.latest_release_id
        else
          params[:release_id]
        end
      end

      def show
        return render_error_json(error: MISSING_MODEL_ERROR) if current_model.nil?

        @releases = current_model.player_releases(player_id:).map(&:to_h)
        add_tournaments!
        render_json(metadata: player_metadata, items: @releases)
      end

      def player_id
        @player_id ||= params[:player_id].to_i
      end

      def add_tournaments!
        tournaments = current_model.player_tournaments(player_id:)

        tournaments_hash = tournaments.each_with_object({}) do |tournament, hash|
          next unless tournament.in_rating

          (hash[tournament["release_id"]] ||= []) << tournament.to_h.except(:release_id)
        end

        @releases.each do |release|
          release["tournaments"] = tournaments_hash[release[:id]]
        end
      end

      def player_metadata
        metadata = {
          model: current_model.name,
          player_id:
        }

        metadata[:name] = Player.find(player_id).full_name if add_names?
        metadata
      end
    end
  end
end
