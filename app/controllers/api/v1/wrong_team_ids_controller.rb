module API
  module V1
    class WrongTeamIdsController < APIController
      def index
        render json: {items: WrongTeamId.all}, status: :ok
      end
    end
  end
end
