# frozen_string_literal: true

require "httparty"

module ChgkInfo
  class APIClient
    include HTTParty

    base_uri "api.rating.chgk.info"

    extend Limiter::Mixin

    limit_method :fetch, rate: 60, balanced: true

    ITEMS_PER_PAGE = 100

    def initialize
      @headers = {accept: "application/json"}
    end

    def all_tournaments(page:)
      paged_fetch("/tournaments?", page)
    end

    def rating_tournaments(page:)
      paged_fetch("/tournaments?properties.ggRating=true", page)
    end

    def tournaments_starting_between(start_date:, end_date:, page:)
      paged_fetch("/tournaments?dateStart%5Bafter%5D=#{start_date}&dateStart%5Bbefore%5D=#{end_date}", page)
    end

    def tournaments_updated_after(date:, page:)
      paged_fetch("/tournaments?lastEditDate%5Bafter%5D=#{date}", page)
    end

    def tournament_results(tournament_id:)
      params = "results?includeTeamMembers=0&includeMasksAndControversials=1&includeTeamFlags=0&includeRatingB=0"
      fetch("/tournaments/#{tournament_id}/#{params}")
    end

    def tournament_rosters(tournament_id:)
      params = "results?includeTeamMembers=1&includeMasksAndControversials=0&includeTeamFlags=1&includeRatingB=0"
      fetch("/tournaments/#{tournament_id}/#{params}")
    end

    def team_rosters(team_id:)
      fetch("/teams/#{team_id}/seasons?page=1&itemsPerPage=500")
    end

    def towns(page:)
      paged_fetch("/towns?", page)
    end

    def teams(page:)
      fetch("/teams?page=#{page}&itemsPerPage=500")
    end

    def players(page:)
      fetch("/players?page=#{page}&itemsPerPage=500")
    end

    def seasons
      fetch("/seasons")
    end

    def tournament_appeals(tournament_id:)
      fetch("/tournaments/#{tournament_id}/appeals?page=1")
    end

    private

    def paged_fetch(query, page)
      fetch("#{query}&itemsPerPage=#{ITEMS_PER_PAGE}&page=#{page}")
    end

    def fetch(query)
      response = self.class.get(query.to_s, headers: @headers)
      JSON.parse(response.body)
    rescue SocketError, Errno::ECONNREFUSED, Errno::ETIMEDOUT, JSON::ParserError
      logger.warn "connection refused at #{query}, retrying in 3 seconds"
      sleep(3)
      retry
    end
  end
end
