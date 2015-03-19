module EventStore
  module Client
    class Builder

      setting :host
      setting :port

      def self.build
        new.tap do |instance|
          EventStore::Settings.instance.set instance
        end
      end

      def self.configure(receiver)
        instance = build
        logger = Logger.get self
        logger.trace "Configuring Client"

        client = Vertx::HttpClient.new.tap do |client|
          client.host = instance.host
          client.port = instance.port
        end

        receiver.client = client
        client
      end
    end
  end
end
