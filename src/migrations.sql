-- This file provides a method for applying incremental schema changes
-- to a PostgreSQL database.

-- Add your migrations at the end of the file, and run "psql -v ON_ERROR_STOP=1 -1f
-- migrations.sql yourdbname" to apply all pending migrations. The
-- "-1" causes all the changes to be applied atomically

-- Most Rails (ie. ActiveRecord) migrations are run by a user with
-- full read-write access to both the schema and its contents, which
-- isn't ideal. You'd generally run this file as a database owner, and
-- the contained migrations would grant access to less-privileged
-- application-level users as appropriate.

-- Refer to https://github.com/purcell/postgresql-migrations for info and updates

--------------------------------------------------------------------------------
-- A function that will apply an individual migration
--------------------------------------------------------------------------------
DO
$body$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_proc WHERE proname = 'apply_migration') THEN
    CREATE FUNCTION apply_migration (migration_name TEXT, ddl TEXT) RETURNS BOOLEAN --NOT NULL DEFAULT FALSE
      AS $$
    BEGIN
      IF NOT EXISTS (SELECT FROM pg_catalog.pg_tables WHERE tablename = 'applied_migrations') THEN
        CREATE TABLE applied_migrations (
            identifier TEXT NOT NULL PRIMARY KEY
          , ddl TEXT NOT NULL
          , applied_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
        );
      END IF;
      LOCK TABLE applied_migrations IN EXCLUSIVE MODE;
      IF NOT EXISTS (SELECT 1 FROM applied_migrations m WHERE m.identifier = migration_name)
      THEN
        RAISE NOTICE 'Applying migration: %', migration_name;
        EXECUTE ddl;
        INSERT INTO applied_migrations (identifier, ddl) VALUES (migration_name, ddl);
        RETURN TRUE;
      END IF;
      RETURN FALSE;
    END;
    $$ LANGUAGE plpgsql;
  END IF;
END
$body$;


SELECT apply_migration(
  'initial_migration',
  $$
    CREATE TYPE header_pair AS (
      "name" TEXT,
      "value" BYTEA
    );

    CREATE TABLE transaction (
      user_id VARCHAR(100) NOT NULL,
      transaction_key TEXT NOT NULL,
      response_status_code SMALLINT,
      response_headers header_pair[],
      response_body BYTEA,
      created_at timestamptz NOT NULL,
      PRIMARY KEY(user_id, transaction_key)
    );

    CREATE TABLE super_user (
      user_id VARCHAR(100) NOT NULL PRIMARY KEY,
      delegate_flg BOOLEAN NOT NULL DEFAULT FALSE,
      immutable_flg BOOLEAN NOT NULL DEFAULT FALSE
    );

    CREATE TABLE permission (
      id SERIAL PRIMARY KEY,
      "name" VARCHAR(100) NOT NULL UNIQUE,
      "description" TEXT,
      immutable_flg BOOLEAN NOT NULL DEFAULT FALSE,
      UNIQUE ("name")
    );

    CREATE TABLE role (
      id SERIAL PRIMARY KEY,
      "name" VARCHAR(100) NOT NULL UNIQUE,
      "description" TEXT,
      immutable_flg BOOLEAN NOT NULL DEFAULT FALSE,
      UNIQUE ("name")
    );

    CREATE TABLE role_permission (
      id SERIAL PRIMARY KEY,
      role_id BIGINT REFERENCES "role"(id) ON DELETE CASCADE,
      permission_id BIGINT REFERENCES "permission"(id) ON DELETE CASCADE,
      delegate_flg BOOLEAN NOT NULL DEFAULT FALSE,
      immutable_flg BOOLEAN NOT NULL DEFAULT FALSE,
      UNIQUE (role_id, permission_id)
    );

    CREATE TABLE user_permission (
      id SERIAL PRIMARY KEY,
      user_id VARCHAR(100),
      permission_id BIGINT REFERENCES "permission"(id) ON DELETE CASCADE,
      delegate_flg BOOLEAN NOT NULL DEFAULT FALSE,
      immutable_flg BOOLEAN NOT NULL DEFAULT FALSE,
      UNIQUE (user_id, permission_id)
    );

    CREATE TABLE user_role (
      id SERIAL PRIMARY KEY,
      user_id VARCHAR(100),
      role_id BIGINT REFERENCES "role"(id) ON DELETE CASCADE,
      delegate_flg BOOLEAN NOT NULL DEFAULT FALSE,
      immutable_flg BOOLEAN NOT NULL DEFAULT FALSE,
      UNIQUE (user_id, role_id)
    );
  $$
);