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

      settings.connection.prepare(
        'select_publishers',
        'SELECT * FROM publishers WHERE page IS NOT NULL OFFSET 2000 LIMIT 2000'
      )

      settings.connection.prepare(
        'select_max_publishers_page', 'SELECT MAX(page) FROM publishers'
      )

      settings.connection.prepare(
        'select_author_id_by_name', 'SELECT id FROM authors WHERE name = $1'
      )

      settings.connection.prepare(
        'insert_author',
        'INSERT INTO authors (name, nationality) VALUES ($1, $2) RETURNING id'
      )

      settings.connection.prepare(
        'select_language_id_by_name', 'SELECT id FROM languages WHERE name = $1'
      )

      settings.connection.prepare(
        'insert_language',
        'INSERT INTO languages (name) VALUES ($1) RETURNING id'
      )

      settings.connection.prepare(
        'select_genre_id_by_name', 'SELECT id FROM genres WHERE name = $1'
      )

      settings.connection.prepare(
        'insert_genre',
        'INSERT INTO genres (name) VALUES ($1) RETURNING id'
      )

      settings.connection.prepare(
        'select_category_id_by_name', 'SELECT id FROM categories WHERE name = $1'
      )

      settings.connection.prepare(
        'insert_category',
        'INSERT INTO categories (name) VALUES ($1) RETURNING id'
      )

      settings.connection.prepare(
        'select_book_id_by_isbn', 'SELECT id FROM books WHERE isbn = $1'
      )

      settings.connection.prepare(
        'insert_book',
        'INSERT INTO books ' \
        '(isbn, publisher_id, language_id, genre_id, category_id, title, ' \
        'cover, issue, publish_date, description, copies, price) ' \
        'VALUES ' \
        '($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) RETURNING id'
      )

      settings.connection.prepare(
        'select_books_author_id_by_ids',
        'SELECT id FROM books_authors WHERE book_id = $1 AND author_id = $2'
      )

      settings.connection.prepare(
        'insert_books_author',
        'INSERT INTO books_authors (book_id, author_id) VALUES ($1, $2)'
      )

      settings.connection.prepare(
        'insert_isbn',
        'INSERT INTO isbns (isbn, book_id) VALUES ($1, $2)'
      )

      @prepared = true
    end
  end
end
