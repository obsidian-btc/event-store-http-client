module EventStore
  module HttpClient
    module Writer
      def configure(receiver)
        es_writer = EventStore::HttpClient::Events::Write
        receiver.es_writer = es_writer
        es_writer
      end
    end
  end
end
