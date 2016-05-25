#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.join(__dir__, '..', 'lib'))

require 'reacto'
require 'rest-client'
require 'nokogiri'
require 'pg'

require 'reacto/http'

require 'bookworm/settings'
require 'bookworm/prepared_statements'

settings = Bookworm::Settings.instance
Bookworm::PreparedStatements.prepare!(settings)

start_page = settings.connection.exec(
  'SELECT MAX(page) FROM publishers'
).first['max'] || 0
start_page = start_page.to_i
start_page += 1

results = Reacto::HTTP.get('http://www.booksinprint.bg/Publisher/Search')
  .map { |value| Nokogiri::HTML(value) }
  .map { |value| value.css('div.pageing div.right') }
  .map(&:children).map(&:first).map(&:text).map(&:strip)
  .map { |value| value.scan(/\d+/) }
  .map(&:flatten).map(&:first).map(&:to_i)
  .map { |value| (value / 10) + 1 }
  .flat_map { |value| Reacto::Trackable.interval(5, (start_page..value).each) }
  .map do |value|
    response = RestClient.get(
      "http://www.booksinprint.bg/Publisher/Search?page=#{value}"
    )
    {
      page: value,
      response: response
    }
  end
  .map do |value|
    { page: value[:page], data: Nokogiri::HTML(value[:response]) }
  end
  .flat_map do |value|
    data = value[:data].css('table.results tr').map do |tag|
      { page: value[:page], data: tag }
    end
    Reacto::Trackable.enumerable(data)
  end
  .select { |value| value[:data].children.first.name == 'td' }
  .map { |value| { page: value[:page], data: value[:data].children.first } }
  .flat_map do |value|
    link = value[:data].css('a').attr('onclick').value
      .scan(/^\$\.submitPage\('(.+?)'.*$/).flatten.first

    name_code = value[:data].text.strip.scan(/^(.+), код ([\d-]+)$/).flatten
    basic = { name: name_code.first, code: name_code.last, page: value[:page] }

    Reacto::HTTP.get("http://www.booksinprint.bg#{link}")
      .map { |val| Nokogiri::HTML(val) }
      .map { |document| document.css('fieldset') }
      .wrap(basic)
  end
  .map(&:to_h)

consumer = ->(value) do
  p value
  return if value[:code].nil? || value[:name].nil?

  p "#{value[:code]} -> #{value[:name]}"

  settings.connection.transaction do |connection|
    record = connection.exec_prepared('select_publisher_by_code', [
      value[:code]
    ]).first

    if record.nil?
      connection.exec_prepared('insert_publisher', [
        value[:name], value[:code], value[:page]
      ])
    else
      connection.exec_prepared('insert_publisher_alias', [
        value[:name], record['id']
      ])
    end
  end
end


subscription = results.on(
  value: consumer,
  error: ->(e) { raise e },
  close: ->() { p 'Done' }
)
results.await(subscription)
