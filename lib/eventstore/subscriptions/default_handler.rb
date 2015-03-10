module Eventstore
  module Subscriptions


    class DefaultHandler

      def configure(receiver)
        receiver.handler = self
        self
      end

      def self.build
        new
      end

      def !(event, attempt=0)
        if rand(1000) < 200
          raise UnrecoverableHandlingError if attempt > 0
          raise RetryableHandlingError
        end
        time = JSON.parse(event['data'])['time']
        puts "Elapsed Time: #{Time.now - Time.at(time)}"
      end
    end
  end
end


# module Customers
#   module Eventstore
#     class MultiCommandHandler
#       Logger.register self
#       dependency :logger, Logger

#       def configure(receiver)
#         receiver.handler = self
#         self
#       end

#       def self.build
#         new.tap do |instance|
#           Logger.configure instance
#         end
#       end

#       def !(event)
#         logger.trace "Event sourced: #{event}"
#         command = command(event)

#         logger.trace "Executing #{command.class} on #{event}"
#         commands = *[command].flatten
#         commands.map(&:!)
#         logger.debug "Executed #{command.class}"
#       end

#       def command(event)
#         if event['eventType'] == 'createdCustomer'
#           return SomeCommand.build(JSON.parse(event['data']))
#         else
#           return
#         end
#       end
#     end

#     class SomeCommand
#       extend ScottCommand
#     end
#   end
# end