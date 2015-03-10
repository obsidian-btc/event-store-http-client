require 'vertx'

require 'init'
require 'eventstore/subscriptions/default_handler'

class Something
  dependency :es_writer

  def work
    es_writer.!(type: "EventType",
                data: { "something" => "has data", "value" => rand(100), "time" => Time.now.to_f },
                stream_name: 'newstream')
  end

  def self.build
    new.tap do |instance|
      Eventstore::Writer.configure instance
    end
  end
end


something = Something.build
Vertx.set_periodic(100) {
  something.work
}

Eventstore::Subscriptions::Subscribe.!(starting_point: 0, stream: 'newstream', handler: Eventstore::Subscriptions::DefaultHandler.build)