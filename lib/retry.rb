class Retry

  Logger.register self

  def self.!(block, attempt=0)
    logger = Logger.get self
    logger.trace "Executing #{block}, attempt: #{attempt}"
    begin
      block.call(attempt)
    rescue RetryableHandlingError => e
      logger.info "Exception in #{block}, retrying"
      attempt += 1
      Retry.!(block, attempt)
    rescue UnrecoverableHandlingError => e
      logger.error e
    end
  end
end

class RetryableHandlingError < StandardError ; end
class UnrecoverableHandlingError < StandardError ; end