require 'dependency'
Dependency.activate

require 'logger'
require 'uuid'
require 'settings'
Settings.activate

require 'retry'
require 'eventstore/settings'
require 'eventstore/client/builder'
require 'eventstore/eventstore'
require 'eventstore/events/read'
require 'eventstore/events/write'
require 'eventstore/subscriptions/subscribe'
require 'eventstore/projection/get_state'