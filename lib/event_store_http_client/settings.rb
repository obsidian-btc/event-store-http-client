module EventStore
  module HTTPClient
    class Settings < ::Settings
      def self.instance
        @instance ||= build
      end
    end
  end
end
