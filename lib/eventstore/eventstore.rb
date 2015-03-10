module Eventstore
  class RetryableHandlingError < StandardError ; end

  class UnrecoverableHandlingError < StandardError ; end

  def configure(subject, receiver=nil)
    receiver ||= subject
    eventstore = get(subject)
    receiver.eventstore = eventstore
    eventstore
  end

  def get(subject)
  end
end