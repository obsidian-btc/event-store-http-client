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
      @event_data = { "something" => "has data", "value" => rand(100), "time" => Time.now.to_f }.to_json
      @client = client
    end

    def !
      request = client.post('/streams/newstream') do |resp|
        # puts "got response #{resp.status_code}"
        resp.body_handler do |body|
          # puts "The total body received was #{body.length} bytes"
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
      @starting_point = rand(500)
      @previous_link = nil
    end

    def !
      p "Starting from #{@starting_point}"
      make_request
    end

    def make_request

      p link = @previous_link || "/streams/newstream/#{@starting_point}/forward/20"
      body_embed = "#{link}?embed=body"
      request = @client.get(body_embed) do |resp|
        # puts "got response #{resp.status_code}"
        resp.body_handler do |body|
          # puts "The total body received was #{body.length} bytes"
          if body.length > 0
            parsed_body = JSON.parse(body.to_s)

            links = parsed_body['links']
            if previous_link = parsed_body['links'].find{|link| link['relation'] == 'previous'}
              @previous_link = previous_link['uri']
            end
            parsed_body['entries'].reverse.map{|e| HandleEvent.!(e)}
          else
            p 'empty'
          end
          make_request

        end
      end

      request.put_header('Accept', 'application/vnd.eventstore.atom+json')
      request.put_header('ES-LongPoll', 10)

      request.end
    end
  end

  class HandleEvent
    def self.!(event)
      time = JSON.parse(event['data'])['time']
      puts "Elapsed Time: #{Time.now - Time.at(time)}"
    end
  end
end

Vertx.set_periodic(2_000) { TestStream::WriteEvent.! }
TestStream::Poll.!
