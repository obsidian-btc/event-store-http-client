require 'vertx'

require 'lib/eventstore/subscriptions/subscribe'
require 'lib/eventstore/subscriptions/default_handler'

require 'lib/eventstore/events/write'

Vertx.set_periodic(100) {
  Eventstore::Events::Write.!( type: "EventType",
                            data: { "something" => "has data", "value" => rand(100), "time" => Time.now.to_f },
                            stream_name: 'newstream')
}

Eventstore::Subscriptions::Subscribe.!(starting_point: rand(500), stream: 'newstream', handler: Eventstore::Subscriptions::DefaultHandler)