require 'vertx'

require 'init'
require 'event_store/subscriptions/default_handler'

module Example
  module EventStore
    module Writer
      extend ::EventStore::Writer
    end
  end
end

class Something
  dependency :es_writer

  def work
    es_writer.!(type: "EventType",
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

EventStore::Subscriptions::Subscribe.!(starting_point: 0, stream: 'newstream', handler: EventStore::Subscriptions::DefaultHandler.build)