module EventStore
  module HTTPClient

    def self.subscribe(starting_point, stream, handler)
      Subscriptions::Subscribe.!(
        starting_point: starting_point,
        stream: stream,
        handler: handler
      )
    end

    module Subscriptions
      class Subscribe

        attr_accessor :stream
        attr_accessor :starting_point
        attr_accessor :request_string
        attr_accessor :handler

        dependency :client
        dependency :logger, Logger

        def self.!(params)
          instance = build(params)
          instance.!
        end

        def self.build(params)
          starting_point = params[:starting_point]
          stream = params[:stream]
          handler = params[:handler]
          new(stream, starting_point).tap do |instance|
            handler.configure instance
            EventStore::HTTPClient::Client::Builder.configure instance
            Logger.configure instance
          end
        end

        def initialize(stream, starting_point)
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
            resp.body_handler = body_handler
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

        def body_handler(body)
          if body.length > 0
            handle_success(body)
          else
            handle_failure(:unknown)
          end
        end


        def handle_success(raw_body)
          body = JSON.parse(raw_body.to_s)
          links = body['links']

          body['entries'].reverse.map{|e|
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
        end

        def handle_failure(status_code)
          logger.error "There was an error (#{status_code}) with the subscription request.  Retrying"
          Vertx.set_timer(rand(1000)+10) do
            make_request
          end
        end

      end
    end
  end
end
