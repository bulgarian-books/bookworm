CREATE TABLE IF NOT EXISTS publishers (
  id          serial PRIMARY KEY,
  name        varchar(255) NOT NULL,
  code        varchar(20) NOT NULL UNIQUE,
  state       varchar(8) DEFAULT 'inactive',
  page        int NOT NULL,
  created_at  timestamp DEFAULT now(),
  updated_at  timestamp DEFAULT now()
);

CREATE INDEX publishers_name_idx ON publishers (name);

CREATE TABLE IF NOT EXISTS publisher_aliases (
  id            serial PRIMARY KEY,
  publisher_id  integer REFERENCES publishers (id),
  name          varchar(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS publisher_contacts (
  id            serial PRIMARY KEY,
  publisher_id  integer REFERENCES publishers (id),
  name          varchar(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS publisher_addresses (
  id            serial PRIMARY KEY,
  publisher_id  integer REFERENCES publishers (id),
  town          varchar(255) NOT NULL,
  main          varchar(255),
  phone         varchar(255),
  email         varchar(255),
  site          varchar(255)
);

CREATE INDEX publisher_addresses_town_idx ON publisher_addresses (town);

CREATE TABLE IF NOT EXISTS authors (
  id            serial PRIMARY KEY,
  name          varchar(255) NOT NULL,
  nationality   varchar(255) NOT NULL
);

CREATE INDEX authors_name_idx ON authors (name);

CREATE TABLE IF NOT EXISTS languages (
  id            serial PRIMARY KEY,
  name          varchar(255) NOT NULL
);

CREATE INDEX languages_name_idx ON languages (name);

CREATE TABLE IF NOT EXISTS genres (
  id            serial PRIMARY KEY,
  name          varchar(255) NOT NULL
);

CREATE INDEX genres_name_idx ON genres (name);

CREATE TABLE IF NOT EXISTS categories (
  id            serial PRIMARY KEY,
  name          varchar(255) NOT NULL
);

CREATE INDEX categories_name_idx ON categories (name);

CREATE TABLE IF NOT EXISTS books (
  id            serial PRIMARY KEY,
  isbn          varchar(20) NOT NULL UNIQUE,
  publisher_id  integer REFERENCES publishers (id),
  author_id     integer REFERENCES authors (id),
  language_id   integer REFERENCES languages (id),
  genre_id      integer REFERENCES genres (id),
  category_id   integer REFERENCES categories (id),
  title         varchar(255) NOT NULL,
  cover         varchar(255) NOT NULL,
  issue         int NOT NULL,
  publish_date  timestamp,
  created_at  timestamp DEFAULT now(),
  updated_at  timestamp DEFAULT now()
);

CREATE INDEX books_title_idx ON books (title);
