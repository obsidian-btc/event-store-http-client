module EventStore
  class Settings
    def self.instance
      @instance ||= ::Settings.build('settings.json')
    end
  end
end