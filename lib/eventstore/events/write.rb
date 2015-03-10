module Eventstore
  module Events
    class Write
      Logger.register self

      attr_accessor :client
      attr_accessor :data
      attr_accessor :id
      attr_accessor :stream_name
      attr_accessor :type

      dependency :logger, Logger

      def self.!(params)
        instance = build(params)
        instance.!
      end

      def self.build(params)
        type = params[:type]
        data = params[:data].to_json
        stream_name = params[:stream_name]

        new(type, data, stream_name, client).tap do |instance|
          Logger.configure instance
          instance.id = java.util.UUID.randomUUID().to_s
        end
      end

      def self.client
        logger = Logger.get self
        @client ||= Vertx::HttpClient.new.tap do |client|
          logger.info "Initializing Client"
          client.port = 2113
          client.host = 'localhost'
        end
      end

      def initialize(type, data, stream_name, client)
        @type = type
        @data = data
        @stream_name = stream_name
        @client = client
      end

      def !
        make_request
      end

      def make_request
        request = client.post("/streams/#{stream_name}") do |resp|
          Logger.debug "Response #{resp.status_code}"

          resp.body_handler do |body|

            # puts "The total body received was #{body.length} bytes"
            # puts body
          end
        end

        request.put_header('ES-EventType', type)
        request.put_header("ES-EventId", id)
        request.put_header('Accept', 'application/vnd.eventstore.atom+json')
        request.put_header('Content-Length', data.length)
        request.put_header('Content-Type', 'application/json')

        request.exception_handler { make_request }

        request.write_str(data)

        request.end
      end
    end
  end
end