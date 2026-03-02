class ReleasePresenter
  attr_reader :id, :teams, :teams_in_release_count

  def initialize(id:, teams:)
    @id = id
    @teams = teams
  end
end
