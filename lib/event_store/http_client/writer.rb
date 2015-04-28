module EventStore
  module HTTPClient
    module Writer
      def configure(receiver)
        es_writer = EventStore::HTTPClient::Events::Write.build
        receiver.es_writer = es_writer
        es_writer
      end

      module NullObject
        def self.build
          Substitute.new
        end
      end

      class Substitute
        def events
          @events ||= []
        end

        def !(data)
          event = Event.build data
          events << event
          event
        end

        def sent?(event)
          events.include? event
        end
      end
    end
  end
end
