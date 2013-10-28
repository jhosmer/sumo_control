require 'faraday'

module SumoControl
  class Client
    API_HOST = 'https://api.sumologic.com'

    attr_reader :connection

    def initialize(user, password)
      @connection = Faraday.new(:url => API_HOST) do |r|
        r.response :logger
        r.adapter Faraday.default_adapter
      end
      @connection.basic_auth(user, password)
    end

    def sources(collector_id)
      connection.get "/api/v1/collectors/#{collector_id}/sources"
    end

    def create_source(collector_id, source_definition)
      connection.post do |req|
        req.url "/api/v1/collectors/#{collector_id}/sources"
        req.headers['Content-Type'] = 'application/json'
        req.body = source_definition.to_json
      end
    end
  end
end
