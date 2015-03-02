require 'vertx'

require 'lib/eventstore/subscriptions/subscribe'
require 'lib/eventstore/subscriptions/default_handler'

module TestStream
  class WriteEvent
    attr_reader :event_data
    attr_reader :client
    def self.!
      new(client).!
    end

    def self.client
      @client ||= Vertx::HttpClient.new.tap do |client|
        p "Initializing Client"
        client.port = 2113
        client.host = 'localhost'
      end
    end

    def initialize(client)
      @event_data = { "something" => "has data", "value" => rand(100), "time" => Time.now.to_f }.to_json
      @client = client
    end

    def !
      request = client.post('/streams/newstream') do |resp|
        # puts "got response #{resp.status_code}"
        resp.body_handler do |body|
          # puts "The total body received was #{body.length} bytes"
          # puts body
        end
      end

      request.put_header('ES-EventType', 'SomeEvent')
      request.put_header("ES-EventId", java.util.UUID.randomUUID().to_s)
      request.put_header('Accept', 'application/vnd.eventstore.atom+json')
      request.put_header('Content-Length', event_data.length)
      request.put_header('Content-Type', 'application/json')
      request.write_str(event_data)

      request.end
    end
  end
end

Vertx.set_periodic(100) { TestStream::WriteEvent.! }

Eventstore::Subscriptions::Subscribe.!(starting_point: rand(500), stream: 'newstream', handler: Eventstore::Subscriptions::DefaultHandler)