require 'reacto'
require 'pg'

module Reacto
  module PG
    class Select < Trackable
      class << self
        def exec(connection, prepared_name, params = nil)
          make do |tracker|
            begin
              records = connection.exec_prepared(prepared_name, params)
              records.each { |row| tracker.on_value(row) }

              tracker.on_close
            rescue StandardError => e
              tracker.on_error(e)
            end
          end
        end
      end
    end
  end
end
