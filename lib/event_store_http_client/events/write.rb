module EventStore
  module HTTPClient
    module Events
      class Write

        attr_accessor :data
        attr_accessor :id
        attr_accessor :stream_name
        attr_accessor :location
        attr_accessor :version
        attr_accessor :type

        dependency :logger, Telemetry::Logger
        dependency :settings
        dependency :client

        def !(params)
          @type = params[:type]
          @version = params[:version]
          @data = params[:data].to_json
          @stream_name = params[:stream_name]

          make_request do |result|
            yield result
          end
        end

        def make_request
          logger.debug "Making request to #{stream_name}"
          request = client.post("/streams/#{stream_name}") do |resp|
            logger.debug "Response #{resp.status_code}"

            if resp.status_code == 201
              yield :success if block_given?
            else
              yield resp.status_code if block_given?
            end
            resp.body_handler do |body|
              # puts "The total body received was #{body.length} bytes"
              # puts body
            end
          end

          request.put_header('ES-EventType', type)
          request.put_header("ES-EventId", id)
          request.put_header("ES-ExpectedVersion", version) if version
          request.put_header('Accept', 'application/vnd.eventstore.atom+json')
          request.put_header('Content-Length', data.length)
          request.put_header('Content-Type', 'application/json')

          request.exception_handler { |e|
            logger.error "Event #{id} failed to write, trying again"
            logger.error e
            Vertx.set_timer(rand(1000)+10) do
              make_request do |result|
                yield result
              end
            end
          }

          request.write_str(data)

          request.end
        end

        def self.!(params)
          instance = build
          instance.!(params) do |result|
            yield result if block_given?
          end
        end

        def self.build
          new.tap do |instance|
            Telemetry::Logger.configure instance
            EventStore::HTTPClient::Client::Builder.configure instance
            instance.id = UUID::Random.get
          end
        end
      end
    end
  end
end
