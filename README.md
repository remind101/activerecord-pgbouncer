# ActiveRecord PgBouncer Connection Adapter [![Build Status](https://travis-ci.org/remind101/activerecord-pgbouncer.svg?branch=master)](https://travis-ci.org/remind101/activerecord-pgbouncer)

When using PgBouncer, there are certain considerations to take into account:

* If you're using transaction pooling mode, prepared statements must be disabled.
* If you're using transaction pooling mode, session level features should not be used.

This is a light layer above the PostgreSQL connection adapter, that helps ensure that you don't make the mistakes above!

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'activerecord-pgbouncer'
```

## Usage

This adds a `pgbouncer` adapter, which you can use in `config/database.yml` or `ENV['DATABASE_URL']`:

```yaml
production:
  adapter: pgbouncer
  pooling_mode: transaction # Can be `session`, `transaction`, or `statement`
```

```shell
export DATABASE_URL=pgbouncer://user:pass@host/db?pooling_mode=transaction
```
