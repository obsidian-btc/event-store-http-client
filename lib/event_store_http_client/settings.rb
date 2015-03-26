module EventStore
  module HttpClient
    class Settings < ::Settings
      def self.instance
        @instance ||= build
      end
    end
  end
end
