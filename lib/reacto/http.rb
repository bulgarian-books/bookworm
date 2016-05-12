require 'reacto/http/request'

module Reacto
  module HTTP
    module_function

    def get(url)
      Request.get(url)
    end
  end
end
