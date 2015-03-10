class Retry
  Logger.register self

  def self.!(block, attempt=0)
    logger = Logger.get self
    p "Executing #{block}, attempt: #{attempt}"
    logger.trace "Executing #{block}, attempt: #{attempt}"
    begin
      block.call(attempt)
    rescue RetryableError => e
      logger.info "Exception in #{block}, retrying"
      attempt += 1
      Retry.!(block, attempt)
    rescue UnretryableError => e
      logger.error e
    end
  end
end

class RetryableError < StandardError ; end
class UnretryableError < StandardError ; end