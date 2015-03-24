module EventStore
  module Handler
    def self.included(cls)
      cls.send :dependency, :logger, Logger
      cls.extend Build unless cls.ancestors.include? Build
    end


    def configure(receiver)
      receiver.handler = self
      self
    end

    def !(event, attempt=0)
      logger.trace "Event sourced: #{event}"
      command = command(event)

      logger.trace "Executing #{command.class} on #{event}"
      command.!
      logger.debug "Executed #{command.class}"
    end

    module Build
      def build
        new.tap do |instance|
          Logger.configure instance
        end
      end
    end

    class NullCommand
      dependency :logger, Logger
      attr_accessor :event_type

      def !
        logger.debug "No command to execute for this eventType (type: #{event_type})"
      end

      def self.build(event_type)
        new.tap do |instance|
          Logger.configure instance
          instance.event_type = event_type
        end
      end
    end

  end
end
