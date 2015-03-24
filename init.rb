require 'bundler'
Bundler.setup

lib_dir = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift lib_dir unless $LOAD_PATH.include?(lib_dir)

require 'dependency'
Dependency.activate

require 'logger'

require 'retry'
p "About to require eventstore"
require 'event_store'
p "Required eventstore"