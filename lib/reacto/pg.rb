require 'reacto/pg/select'

module Reacto
  module PG
    module_function

    def select(connection, prepared_name, params = nil)
      Select.exec(connection, prepared_name, params)
    end
  end
end
