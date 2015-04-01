require 'vertx'

require 'init'

module Example
  module EventStore
    module Writer
      extend ::EventStore::HTTPClient::Writer
    end

    class Handler
      include ::EventStore::HTTPClient::Handler

      def command(event)
        if event['eventType'] == 'exampleEventType'
          return Example::EventStore::Command.build(JSON.parse(event['data']))
        else
          return NullCommand.build(event['eventType'])
        end
      end
    end

    class Command
      dependency :logger, Logger

      def self.build(params)
        new.tap do |instance|
          Logger.configure instance
        end
      end

      def !
        logger.info "Executing Example Command"
      end
    end
  end
end



class Something
  dependency :es_writer

  def work
    es_writer.!(type: "exampleEventType",
                data: { "something" => "has data", "value" => rand(100), "time" => Time.now.to_f },
                stream_name: 'test-stream')
  end

  def self.build
    new.tap do |instance|
      Example::EventStore::Writer.configure instance
    end
  end
end


something = Something.build
Vertx.set_periodic(100) {
  something.work
}

EventStore::HTTPClient::Subscriptions::Subscribe.!(starting_point: 0, stream: 'newstream', handler: Example::EventStore::Handler.build)
