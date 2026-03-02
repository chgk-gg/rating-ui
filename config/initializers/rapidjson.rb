require "rapidjson/json_gem"

ActiveSupport::JSON::Encoding.json_encoder = RapidJSON::ActiveSupportEncoder
