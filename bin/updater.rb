#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.join(__dir__, '..', 'lib'))

require 'date'
require 'reacto'
require 'nokogiri'

require 'reacto/http'

require 'bookworm/settings'
require 'bookworm/prepared_statements'

settings = Bookworm::Settings.instance
Bookworm::PreparedStatements.prepare!(settings)

trackable = Reacto::HTTP.get('http://www.booksinprint.bg/Home/NewEditions')
  .map { |v| Nokogiri::HTML(v) }
  .select { |html| !html.css('div#left-menu-results').empty? }
  .map do |html|
    pages = html.css('.pageing .right').text.strip
    pages = pages.gsub(/\D+/, '').to_i
    pages = (pages / 21.0).ceil

    requests = (2..pages).map do |page|
      Reacto::HTTP.get(
        "http://www.booksinprint.bg/Home/NewEditions?page=#{page}"
      ).retry(3).map { |v| Nokogiri::HTML(v) }
    end

    ([Reacto::Trackable.value(html)] + requests).map do |response|
      response
        .map { |document| document.css('div.book') }
        .map(&:to_a)
        .flatten
        .flat_map do |book|
          publisher_url = book.css('div.publisher a').attr('href').value
          image_src = book.css('.image img').attr('src').value
          image_url = "http://www.booksinprint.bg#{image_src}"
          url = book.css('.title a').attr('href').value

          publisher_id =
            Reacto::HTTP.get("http://www.booksinprint.bg#{publisher_url}")
              .map { |v| Nokogiri::HTML(v) }
              .map { |doc| doc.at('fieldset:contains("Кодове")') }
              .map { |doc| doc.text.strip }
              .map { |text| text.scan(/\d+-\d+-\d+/) }
              .map do |codes|
                param = codes.map { |code| "'#{code}'"}.join(',')
                settings.connection.exec(
                  "SELECT * FROM publishers WHERE code IN (#{param})"
                )
              end
              .map { |result| result.first['id'] }
              .map(&:to_i)

          Reacto::HTTP.get("http://www.booksinprint.bg#{url}")
            .map { |v| Nokogiri::HTML(v) }
            .map { |document| document.css('table.issue') }
            .flat_map do |document|
              Reacto::Trackable.enumerable(document.css('tr'))
            end
            .group_by_label do |document|
              [
                document.css('td.first-col').text.strip,
                document.css('td:last').text.strip
              ]
            end
            .select do |grouped|
              [
                'Националност на автора', 'Тематики', 'Жанр', 'Категория',
                'Поредност на изданието', 'Планирана дата на издаване',
                'Описание', 'Тираж', 'Цена'
              ].include?(grouped.label)
            end
            .map(label: 'Националност на автора') do |val|
              { author_nationality: val }
            end
            .map(label: 'Тематики') do |val|
              { themes: val.split(',').map(&:strip) }
            end
            .map(label: 'Жанр') { |val| { genre: val } }
            .map(label: 'Описание') { |val| { description: val } }
            .map(label: 'Категория') { |val| { category: val } }
            .map(label: 'Поредност на изданието') { |val| { issue: val.to_i } }
            .map(label: 'Тираж') { |val| { copies: val.to_i } }
            .map(label: 'Цена') { |val| { price: val.gsub(',', '').to_i } }
            .map(label: 'Планирана дата на издаване') do |val|
              { publish_date: Date.strptime(val, '%d.%m.%Y') }
            end
            .flatten_labeled.map(&:value)
            .inject({}) { |current, val| current.merge(val) }.last
            .map do |val|
              val.merge(
                title: book.css('.title').text.strip,
                authors: book.css('.author').text.strip,
                isbn: book.css('.isbn').text.strip.gsub('ISBN ', ''),
                series: book.css('.series').text.gsub('серия:', '').strip,
                cover: book.css('.binding').text.gsub('подвързия:', '').strip,
                format: book.css('.format').text.gsub('формат:', '').strip,
                language: book.css('.language').text.gsub('език:', '').strip,
                image_url: image_url
              )
            end
            .depend_on(publisher_id, key: :publisher_id)
            .map { |val| val.value.merge(publisher_id: val.publisher_id) }
        end
    end
  end
  .flatten.flat_map { |value| value }

consumer = ->(value) do
  p "#{value[:title]} : #{value[:publisher_id]}"

  settings.connection.transaction do |connection|
    isbns = value[:isbn].split(';')
    primary_isbn = isbns.find { |isbn| isbn.start_with?('978') } || isbns.first

    data =
      connection.exec_prepared('select_book_id_by_isbn', [primary_isbn]).first
    unless data.nil?
      p 'Already stored.'
      return
    end

    publisher_id = value[:publisher_id]

    author_names = value[:authors]
      .gsub('и др.', '')
      .gsub('Под редакцията на ', '')
      .split(',')
      .map(&:strip)
    author_ids = author_names.map do |name|
      data = connection.exec_prepared('select_author_id_by_name', [name]).first
      if data.nil?
        data = connection.exec_prepared(
          'insert_author', [name, value[:author_nationality]]
        ).first
      end
      data['id'].to_i
    end

    data = connection.exec_prepared(
      'select_language_id_by_name', [value[:language]]
    ).first
    data = connection.exec_prepared(
      'insert_language', [value[:language]]
    ).first if data.nil?
    language_id = data['id'].to_i

    genre_id =
      if value[:genre]
        data = connection.exec_prepared(
          'select_genre_id_by_name', [value[:genre]]
        ).first
        data = connection.exec_prepared(
          'insert_genre', [value[:genre]]
        ).first if data.nil?

        data['id'].to_i
      end

    category_id =
      if value[:category]
        data = connection.exec_prepared(
          'select_category_id_by_name', [value[:category]]
        ).first
        data = connection.exec_prepared(
          'insert_category', [value[:category]]
        ).first if data.nil?

        data['id'].to_i
      end

    issue = value[:issue] || 1

    data = connection.exec_prepared(
      'insert_book',
      [
        primary_isbn, publisher_id, language_id, genre_id, category_id,
        value[:title], value[:image_url], issue, value[:publish_date],
        value[:description], value[:copies], value[:price]
      ]
    ).first
    book_id = data['id'].to_i

    author_ids.each do |author_id|
      data = connection.exec_prepared(
        'select_books_author_id_by_ids', [book_id, author_id]
      ).first
      next unless data.nil?

      connection.exec_prepared('insert_books_author', [book_id, author_id])
    end

    isbns.each do |isbn|
      connection.exec_prepared('insert_isbn', [isbn, book_id])
    end
  end
end

trackable.on(
  value: consumer,
  error: ->(e) { raise e },
  close: ->() { p 'Done' }
)
