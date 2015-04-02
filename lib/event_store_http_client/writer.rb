module EventStore
  module HTTPClient
    module Writer
      def configure(receiver)
        es_writer = EventStore::HTTPClient::Events::Write
        receiver.es_writer = es_writer
        es_writer
      end
    end
  end
end
