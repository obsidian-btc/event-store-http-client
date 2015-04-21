module EventStore
  module HTTPClient
    class Settings < ::Settings
      def self.instance
        @instance ||= build
      end

      def self.data_source
        'settings/event_store_http_client.json'
      end
    end
  end
end
