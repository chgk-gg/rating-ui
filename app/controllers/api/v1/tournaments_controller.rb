module API
  module V1
    class TournamentsController < APIController
      include InModel

      def show
        return render_error_json(error: MISSING_MODEL_ERROR) if current_model.nil?

        tournament_ratings = fetch_tournament_ratings
        render_json(metadata:, items: tournament_ratings)
      end

      def add_names?
        params[:show_names] == "true"
      end

      def fetch_tournament_ratings
        if add_names?
          current_model.tournament_ratings_with_team_names(tournament_id:)
        else
          current_model.tournament_ratings(tournament_id:)
        end
      end

      def metadata
        metadata = {
          model: current_model.name,
          tournament_id: @tournament_id,
          true_dl: TrueDLCalculator.tournament_dl(tournament_id:, model: current_model)
        }

        if add_names?
          tournament_details = Tournament.find(tournament_id)
          metadata[:title] = tournament_details.title
          metadata[:start_date] = tournament_details.start_datetime
          metadata[:end_date] = tournament_details.end_datetime
        end

        metadata
      end

      def tournament_id
        @tournament_id ||= params[:tournament_id].to_i
      end
    end
  end
end
