module Eventstore
  module Subscriptions
    class Subscribe
      Logger.register self

      attr_accessor :client
      attr_accessor :stream
      attr_accessor :starting_point
      attr_accessor :request_string
      attr_accessor :handler

      dependency :logger, Logger

      def self.!(params)
        instance = build(params)
        instance.!
      end

      def self.build(params)
        starting_point = params[:starting_point]
        stream = params[:stream]
        handler = params[:handler]
        new(client, stream, starting_point).tap do |instance|
          handler.configure instance
          Logger.configure instance
        end
      end

      def self.client
        @client ||= Vertx::HttpClient.new.tap do |client|
          p "Initializing Subscribe Client"
          client.port = 2113
          client.host = 'localhost'
        end
      end

      def initialize(client, stream, starting_point)
        @client = client
        @stream = stream
        @starting_point = starting_point
      end

      def !
        logger.info "Starting from #{starting_point}"
        @request_string = "/streams/#{stream}/#{starting_point}/forward/20"
        make_request
      end

      def make_request
        body_embed_link = "#{request_string}?embed=body"

        logger.debug body_embed_link

        request = client.get(body_embed_link) do |resp|

          resp.body_handler do |body|

            if body.length > 0
              parsed_body = JSON.parse(body.to_s)
              links = parsed_body['links']

              parsed_body['entries'].reverse.map{|e|
                logger.trace "Executing handler for #{e} with #{handler.inspect}"
                ::Retry.!(->(attempt){
                  handler.!(e, attempt)
                  #persist_successfully_handled_event(e['id'])
                })
              }

              if previous_link = links.find{|link| link['relation'] == 'previous'}
                @request_string = previous_link['uri']
              end
              make_request
            else
              logger.error "There was an error (#{resp.status_code}) with the subscription request.  Retrying"
              Vertx.set_timer(rand(1000)) do
                make_request
              end
            end


          end
        end

        request.put_header('Accept', 'application/vnd.eventstore.atom+json')
        request.put_header('ES-LongPoll', 15)

        request.exception_handler { |e|
          logger.error "Exception in request: #{e}"
          Vertx.set_timer(1_000) do
            make_request
          end
        }

        request.end
      end
    end
  end
end
