require 'singleton'
require 'yaml'
require 'pg'

module Bookworm
  class Settings
    include Singleton

    attr_reader :database

    def  initialize
      @database = symbol_hash(YAML.load_file("#{root}/config/database.yml"))
    end

    def root
      File.join(File.dirname(__dir__), '..')
    end

    def symbol_hash(hash)
      hash.each_with_object({}) do |(key, value), memo|
        val = value.is_a?(Hash) ? symbol_hash(value) : value
        memo[key.to_sym] = val
      end
    end

    def connection
      @connection ||= PG.connect(**database[:production])
    end

    def connection_close
      return if @connection.nil?

      @connection.finish
      @connection = nil
    end
  end
end
