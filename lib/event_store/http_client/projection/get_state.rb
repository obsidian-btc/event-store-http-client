module EventStore
  module HTTPClient
    module Projection
      class GetState

        attr_accessor :projection
        attr_accessor :partition

        dependency :client
        dependency :logger, Telemetry::Logger

        def self.!(params)
          instance = build(params)
          instance.! do |result|
            yield result
          end
        end

        def self.build(params)
          projection = params[:projection]
          partition = params[:partition]

          new(projection, partition).tap do |instance|
            Telemetry::Logger.configure instance
            EventStore::HTTPClient::Client::Builder.configure instance
          end
        end

        def initialize(projection, partition)
          @projection = projection
          @partition = partition
        end

        def !
          make_request do |result|
            yield result
          end
        end

        def make_request
          logger.debug "Making request to /projection/#{projection}/state?partition=#{partition}"
          request = client.get("/projection/#{projection}/state?partition=#{partition}") do |resp|
            logger.debug "Response #{resp.status_code}"

            resp.body_handler do |body|
              status = resp.status_code == 200 ? :success : :error
              yield({ status: status,
                      status_code: resp.status_code,
                      body: body})
            end
          end

          # If I put this 'Accept' header in, it returns a 406.  Else, it works
          # request.put_header('Accept', 'application/vnd.eventstore.atom+json')
          request.put_header('Content-Type', 'application/json')

          request.exception_handler { |e|
            logger.error "Projection failed to query state, trying again"
            Vertx.set_timer(rand(1000)) do
              make_request
            end
          }


          request.end
        end
      end
    end
  end
end
