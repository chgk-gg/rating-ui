class PlayerComponent < ViewComponent::Base
  attr_reader :player_id, :name
  def initialize(player:)
    @player = player

    if @player.is_a?(Hash)
      flag = @player["flag"]
      @name = "#{@player["first_name"]}&nbsp;#{@player["last_name"]}"
      @player_id = @player["player_id"]
    else
      flag = @player.try(:flag)
      @name = "#{@player.first_name}&nbsp;#{@player.last_name}"
      @player_id = @player.player_id
    end

    @bold = flag == "Б" || flag == "К"
    @italic = flag == "Л"
  end

  def before_render
    return if player_id.blank?

    @player_link = link_to(sanitize(name),
      player_path(player_id:),
      class: "hover:underline text-sm")
  end
end
