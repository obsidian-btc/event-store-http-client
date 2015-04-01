class Retry
  def self.!(block, attempt=0)
    logger = Logger.get self
    logger.debug "Executing #{block}, attempt: #{attempt}"
    begin
      block.call(attempt)
    rescue RetryableError => e
      logger.info "Exception in #{block}, retrying"
      attempt += 1
      Retry.!(block, attempt)
    end
  end
end

class RetryableError < StandardError ; end
