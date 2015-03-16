module Eventstore
  module Projection
    class GetState

      attr_accessor :client
      attr_accessor :projection
      attr_accessor :partition

      dependency :logger, Logger

      def self.!(params)
        instance = build(params)
        instance.! do |result|
          yield result
        end
      end

      def self.build(params)
        projection = params[:projection]
        partition = params[:partition]

        new(projection, partition, client).tap do |instance|
          Logger.configure instance
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

      def initialize(projection, partition, client)
        @projection = projection
        @partition = partition
        @client = client
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
            yield body
          end
        end

        # If I put this 'Accept' header in, it returns a 406.  Else, it works
        # request.put_header('Accept', 'application/vnd.eventstore.atom+json')
        request.put_header('Content-Type', 'application/json')

        request.exception_handler { |e|
          logger.error "Event #{id} failed to read, trying again"
          Vertx.set_timer(rand(1000)) do
            make_request
          end
        }


        request.end
      end
    end
  end
end