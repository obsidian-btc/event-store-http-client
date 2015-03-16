require 'dependency'
Dependency.activate

require 'logger'

require 'eventstore/eventstore'
require 'eventstore/events/write'
require 'eventstore/subscriptions/subscribe'
require 'eventstore/projection/get_state'