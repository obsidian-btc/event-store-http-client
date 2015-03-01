require 'vertx'

@client = Vertx::HttpClient.new
@client.port = 2113
@client.host = 'localhost'

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
      @event_data = { "something" => "has data" }.to_json
      @client = client
    end

    def !
      request = client.post('/streams/newstream') do |resp|
        puts "got response #{resp.status_code}"
        resp.body_handler do |body|
          puts "The total body received was #{body.length} bytes"
          puts body
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

  class Poll
    attr_reader :etag
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
      @client = client
    end

    def !
      Vertx.set_periodic(100) { make_request }
    end

    def make_request
      request = @client.get('/streams/newstream') do |resp|
        puts "got response #{resp.status_code}"
        resp.body_handler do |body|
          puts "The total body received was #{body.length} bytes"
          if body.length > 0
            @etag = JSON.parse(body.to_s)['eTag']
          end
        end
      end
      request.put_header('If-None-Match', etag)
      request.put_header('Accept', 'application/vnd.eventstore.atom+json')

      request.end
    end
  end
end

Vertx.set_periodic(500) { TestStream::WriteEvent.! }
TestStream::Poll.!

# "Initializing Client"
# Succeeded in deploying verticle
# got response 200
# The total body received was 10809 bytes
# got response 200
# The total body received was 10809 bytes
# got response 304
# The total body received was 0 bytes
# got response 304
# The total body received was 0 bytes
# "Initializing Client"
# got response 304
# The total body received was 0 bytes
# got response 201
# The total body received was 0 bytes

# got response 200
# The total body received was 10809 bytes
# got response 304
# The total body received was 0 bytes
# got response 304
# The total body received was 0 bytes
# got response 304
# The total body received was 0 bytes
# got response 304
# The total body received was 0 bytes
# got response 201
# The total body received was 0 bytes

# got response 200
# The total body received was 10809 bytes
# got response 304
# The total body received was 0 bytes
# got response 304
# The total body received was 0 bytes
# got response 304
# The total body received was 0 bytes
# got response 304
# The total body received was 0 bytes
# got response 201
# The total body received was 0 bytes
