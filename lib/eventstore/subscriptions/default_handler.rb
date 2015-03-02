module Eventstore
  module Subscriptions

    class DefaultHandler
      def self.configure(receiver)
        handler = build
        receiver.handler = handler
        handler
      end

      def self.build
        new
      end

      def ! event
        time = JSON.parse(event['data'])['time']
        puts "Elapsed Time: #{Time.now - Time.at(time)}"
      end
    end
  end
end