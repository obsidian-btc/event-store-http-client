module Eventstore
  module Subscriptions
    class Subscribe
      attr_accessor :client
      attr_accessor :stream
      attr_accessor :starting_point
      attr_accessor :request_string
      attr_accessor :handler

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
        end
      end

      def self.client
        @client ||= Vertx::HttpClient.new.tap do |client|
          p "Initializing Client"
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
        p "Starting from #{starting_point}"
        @request_string = "/streams/#{stream}/#{starting_point}/forward/20"
        make_request
      end

      def make_request
        body_embed_link = "#{request_string}?embed=body"

        p body_embed_link

        request = client.get(body_embed_link) do |resp|

          resp.body_handler do |body|

            if body.length > 0
              parsed_body = JSON.parse(body.to_s)
              links = parsed_body['links']

              if previous_link = links.find{|link| link['relation'] == 'previous'}
                @request_string = previous_link['uri']
              end

              parsed_body['entries'].reverse.map{|e| handler.!(e)}
            else
              p 'There was an error with the request somehow.  Retrying'
            end
            make_request

          end
        end

        request.put_header('Accept', 'application/vnd.eventstore.atom+json')
        request.put_header('ES-LongPoll', 1)

        request.exception_handler { make_request }

        request.end
      end
    end
  end
end

