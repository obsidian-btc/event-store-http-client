module Eventstore
  module Writer
    def self.configure(receiver)
      es_writer = Eventstore::Events::Write
      receiver.es_writer = es_writer
      es_writer
    end
  end
end

