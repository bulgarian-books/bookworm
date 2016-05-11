#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.join(__dir__, '..', 'lib'))

require 'reacto'
require 'rest-client'
require 'nokogiri'
require 'pg'

require 'bookworm/settings'

settings = Bookworm::Settings.instance


settings.connection.prepare(
  'select_publishers',
  'SELECT * FROM publishers LIMIT 10'
)

select = Reacto::Trackable.make do |tracker|
  records = settings.connection.exec_prepared('select_publishers')

  records.each { |row| tracker.on_value(row) }

  tracker.on_close
end

results = select
  .flat_map { |value| Reacto::Trackable.interval(5, (start_page..value).each) }

subscription = results.on(
  value: ->(v) { p v },
  error: ->(e) { raise e },
  close: ->() { p 'Done' }
)

results.await(subscription)
