module EventStore
  module Writer
    def configure(receiver)
      es_writer = EventStore::Events::Write
      receiver.es_writer = es_writer
      es_writer
    end
  end
end

