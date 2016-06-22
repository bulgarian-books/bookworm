module Bookworm
  module PreparedStatements
    module_function

    def prepare!(settings)
      return if @prepared

      settings.connection.prepare(
        'insert_publisher',
        'INSERT INTO publishers (name, code, state, page) ' \
        'VALUES ($1, $2, $3, $4) RETURNING id'
      )

      settings.connection.prepare(
        'insert_publisher_alias',
        'INSERT INTO publisher_aliases (name, publisher_id) VALUES ($1, $2)'
      )

      settings.connection.prepare(
        'insert_publisher_contacts',
        'INSERT INTO publisher_contacts (name, publisher_id) VALUES ($1, $2)'
      )

      settings.connection.prepare(
        'insert_publisher_addresses',
        'INSERT INTO publisher_addresses ' \
        '(town, main, phone, email, site, publisher_id) ' \
        'VALUES ($1, $2, $3, $4, $5, $6)'
      )

      settings.connection.prepare(
        'select_publisher_by_code', 'SELECT * FROM publishers WHERE code = $1'
      )

      @prepared = true
    end
  end
end
