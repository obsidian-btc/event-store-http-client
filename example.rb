require 'vertx'

require 'init'
require 'eventstore/subscriptions/default_handler'

Vertx.set_periodic(100) {
  Eventstore::Events::Write.!(type: "EventType",
                              data: { "something" => "has data", "value" => rand(100), "time" => Time.now.to_f },
                              stream_name: 'newstream')
}

Eventstore::Subscriptions::Subscribe.!(starting_point: 0, stream: 'newstream', handler: Eventstore::Subscriptions::DefaultHandler.build)