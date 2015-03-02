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
    attr_accessor :client
    attr_accessor :stream_name
    attr_accessor :starting_point
    attr_accessor :previous_link

    def self.!
      instance = build
      build.!
    end

    def self.build
      new(client).tap do |instance|
        starting_point = rand(500)
        instance.starting_point = starting_point
        stream_name = 'newstream'
        instance.stream_name = stream_name
        instance.previous_link = "/streams/#{stream_name}/#{starting_point}/forward/20"
      end
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
      p "Starting from #{starting_point}"
      make_request
    end

    def make_request
      body_embed_link = "#{previous_link}?embed=body"
      request = client.get(body_embed_link) do |resp|

        resp.body_handler do |body|

          if body.length > 0
            parsed_body = JSON.parse(body.to_s)
            links = parsed_body['links']

            if previous_link = links.find{|link| link['relation'] == 'previous'}
              @previous_link = previous_link['uri']
            end

            parsed_body['entries'].reverse.map{|e| HandleEvent.!(e)}
          else
            p 'There was an error with the request somehow.  Retrying'
          end
          make_request

        end
      end

      request.put_header('Accept', 'application/vnd.eventstore.atom+json')
      request.put_header('ES-LongPoll', 1)

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

Vertx.set_periodic(1653) { TestStream::WriteEvent.! }
TestStream::Poll.!
