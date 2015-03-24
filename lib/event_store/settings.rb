module EventStore
  class Settings < ::Settings
    def self.instance
      @instance ||= build
    end
  end
end