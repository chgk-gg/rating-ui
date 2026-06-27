require "test_helper"

class TournamentTest < ActiveSupport::TestCase
  setup do
    @tournament = Tournament.create!(id: 900_001, title: "Deletable Tournament")
  end

  test "delete_if_stopped_existing_at_source destroys the tournament when the source returns 404" do
    ChgkInfo::APIClient.any_instance
      .expects(:single_tournament)
      .with(id: @tournament.id)
      .returns({"title" => "An error occurred", "detail" => "Not Found", "status" => 404, "type" => "/errors/404"})

    assert @tournament.delete_if_stopped_existing_at_source
    assert_not Tournament.exists?(@tournament.id)
  end

  test "delete_if_stopped_existing_at_source keeps the tournament when it still exists at the source" do
    ChgkInfo::APIClient.any_instance
      .expects(:single_tournament)
      .with(id: @tournament.id)
      .returns({"id" => @tournament.id, "name" => "Нестерка", "longName" => "XXXII Международный турнир"})

    assert_not @tournament.delete_if_stopped_existing_at_source
    assert Tournament.exists?(@tournament.id)
  end
end
