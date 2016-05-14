module Bookworm
  module PreparedStatements
    module_function

    def prepare!(settings)
      return if @prepared

      settings.connection.prepare(
        'insert_publisher',
        'INSERT INTO publishers (name, code, page) VALUES ($1, $2, $3)'
      )

      settings.connection.prepare(
        'insert_publisher_alias',
        'INSERT INTO publisher_aliases (name, publisher_id) VALUES ($1, $2)'
      )

      settings.connection.prepare(
        'select_publisher_by_code', 'SELECT * FROM publishers WHERE code = $1'
      )

      @prepared = true
    end
  end
end
