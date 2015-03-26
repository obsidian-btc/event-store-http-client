module EventStore
  module HttpClient
    module Events
      class Read

        attr_accessor :stream_name
        attr_accessor :body

        dependency :client
        dependency :logger, Logger

        def self.!(params)
          instance = build(params)
          instance.! do |result|
            yield result
          end
        end

        def self.build(params)
          body = params[:body]
          stream_name = params[:stream_name]

          new(stream_name).tap do |instance|
            Logger.configure instance
            EventStore::HttpClient::Client::Builder.configure instance
          end
        end

        def initialize(stream_name)
          @stream_name = stream_name
        end

        def !
          make_request do |result|
            yield result
          end
        end

        def make_request
          logger.debug "Making request to #{stream_name}"
          request = client.get("/streams/#{stream_name}?embed=body") do |resp|
            logger.debug "Response #{resp.status_code}"

            resp.body_handler do |body|
              status = resp.status_code == 200 ? :success : :error
              yield({ status: status,
                      status_code: resp.status_code,
                      body: body.to_s})
            end
          end

          request.put_header('Accept', 'application/vnd.eventstore.atom+json')
          request.put_header('Content-Type', 'application/json')

          request.exception_handler { |e|
            logger.error "Failed to read, trying again"
            Vertx.set_timer(rand(1000)) do
              make_request do |result|
                yield result
              end
            end
          }

          request.end
        end
      end
    end
  end
end
