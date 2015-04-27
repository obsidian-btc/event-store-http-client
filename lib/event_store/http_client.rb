require 'dependency'
Dependency.activate

require 'telemetry/logger'
require 'uuid'
require 'settings'
Settings.activate

require 'retry'
require 'event_store/http_client/settings'
require 'event_store/http_client/handler'
require 'event_store/http_client/client/builder'
require 'event_store/http_client/writer'
require 'event_store/http_client/events/read'
require 'event_store/http_client/events/write'
require 'event_store/http_client/subscriptions/subscribe'
require 'event_store/http_client/projection/get_state'
