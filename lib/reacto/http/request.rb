require 'reacto'
require 'rest-client'

module Reacto
  module HTTP
    class Request < Trackable
      class << self
        def get(url)
          make do |tracker|
            begin
              response = RestClient.get(url)

              tracker.on_value(String.new(response.to_str))
              tracker.on_close
            rescue RestClient::Exception => e
              tracker.on_error(e)
            end
          end
        end
      end
    end
  end
end
