module EventStore
  module HTTPClient
    class Event
      attr_accessor :id
      attr_accessor :type
      attr_accessor :data
      attr_accessor :version
      attr_accessor :stream_name

      def self.build(data)
        data[:id] = UUID.random unless data[:id]

        instance = new

        data.each do |k, v|
          instance.send :"#{k}=", v
        end

        instance
      end

      def ==(other)
        (
          id = other.id &&
          type = other.type &&
          data = other.data &&
          version = other.version &&
          stream_name = other.stream_name
        )
      end
      alias :eql :==
    end
  end
end
