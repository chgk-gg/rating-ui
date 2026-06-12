require "httparty"

module Fly
  class MachinesClient
    include HTTParty

    base_uri "https://api.machines.dev/v1"

    GRAPHQL_URI = "https://api.fly.io/graphql"
    LATEST_IMAGE_QUERY = <<~GRAPHQL.freeze
      query($appName: String!) {
        app(name: $appName) {
          currentReleaseUnprocessed {
            imageRef
          }
        }
      }
    GRAPHQL

    class Error < StandardError; end

    class << self
      def latest_image(app_name)
        body = {query: LATEST_IMAGE_QUERY, variables: {appName: app_name}}.to_json
        response = HTTParty.post(GRAPHQL_URI, headers:, body:)
        unless response.success?
          raise Error, "image lookup for #{app_name} failed with #{response.code}: #{response.body}"
        end

        image = response.parsed_response.dig("data", "app", "currentReleaseUnprocessed", "imageRef")
        raise Error, "no release image found for app #{app_name}" if image.blank?

        image
      end

      def create_machine(app_name, config)
        request(:post, "/apps/#{app_name}/machines", body: {config:}.to_json)
      end

      # Long-polls until the machine reaches the stopped state. Returns true once stopped,
      # false if the timeout elapsed first (the API responds with 408).
      def wait_for_stop(app_name, machine_id, instance_id:, timeout: 30)
        response = get("/apps/#{app_name}/machines/#{machine_id}/wait",
          headers:,
          query: {state: "stopped", instance_id:, timeout:})
        return true if response.success?
        return false if response.code == 408

        raise Error, "waiting for machine #{machine_id} failed with #{response.code}: #{response.body}"
      rescue Net::ReadTimeout, Net::OpenTimeout
        false
      end

      def machine(app_name, machine_id)
        request(:get, "/apps/#{app_name}/machines/#{machine_id}")
      end

      def destroy_machine(app_name, machine_id)
        response = delete("/apps/#{app_name}/machines/#{machine_id}", headers:, query: {force: true})
        return if response.success? || response.code == 404

        raise Error, "destroying machine #{machine_id} failed with #{response.code}: #{response.body}"
      end

      private

      def request(method, path, **options)
        response = public_send(method, path, headers:, **options)
        unless response.success?
          raise Error, "#{method.to_s.upcase} #{path} failed with #{response.code}: #{response.body}"
        end

        response.parsed_response
      end

      def headers
        token = Rails.application.config.fly_api_token
        raise Error, "FLY_API_TOKEN is not set" if token.blank?

        {
          "Authorization" => "Bearer #{token}",
          "Content-Type" => "application/json"
        }
      end
    end
  end
end
