require 'active_record/connection_adapters/postgresql_adapter'

module ActiveRecord
  # This is mostly copy pasta from https://github.com/rails/rails/blob/31ab3aa0e881acfd1475abae602455905a4cadf1/activerecord/lib/active_record/connection_adapters/postgresql_adapter.rb#L20-L42
  module ConnectionHandling
    VALID_PGBOUNCER_CONN_PARAMS = [:host, :hostaddr, :port, :dbname, :user, :password, :connect_timeout,
                         :client_encoding, :options, :application_name, :fallback_application_name,
                         :keepalives, :keepalives_idle, :keepalives_interval, :keepalives_count,
                         :tty, :sslmode, :requiressl, :sslcompression, :sslcert, :sslkey,
                         :sslrootcert, :sslcrl, :requirepeer, :krbsrvname, :gsslib, :service]

    # Establishes a connection to the database that's used by all Active Record objects
    def pgbouncer_connection(config)
      pgbouncer = ConnectionAdapters::PgBouncerAdapter

      conn_params = config.symbolize_keys
      mode = conn_params[:pooling_mode]

      raise "Unknown pooling mode provided: #{mode}" unless pgbouncer::POOLING_MODES.include?(mode)
      disable_session = mode == pgbouncer::TRANSACTION_POOLING || mode == pgbouncer::STATEMENT_POOLING
      raise "Prepared statements cannot be used with pgbouncer in #{mode} pooling mode" if disable_session && conn_params[:prepared_statements]
      raise "Session level variables cannot be used with pgbouncer in #{mode} pooling mode" if disable_session && conn_params[:variables]

      conn_params.delete_if { |_, v| v.nil? }

      # Map ActiveRecords param names to PGs.
      conn_params[:user] = conn_params.delete(:username) if conn_params[:username]
      conn_params[:dbname] = conn_params.delete(:database) if conn_params[:database]

      # Forward only valid config params to PGconn.connect.
      conn_params.keep_if { |k, _| VALID_CONN_PARAMS.include?(k) }

      # The postgres drivers don't allow the creation of an unconnected PGconn object,
      # so just pass a nil connection object for the time being.
      pgbouncer::new(mode, nil, logger, conn_params, config)
    end
  end
end

module ActiveRecord
  module ConnectionAdapters
    class PgBouncerAdapter < PostgreSQLAdapter
      # Most polite method. When client connects, a server connection will be
      # assigned to it for the whole duration it stays connected. When client
      # disconnects, the server connection will be put back into pool. This
      # mode supports all PostgeSQL features.
      SESSION_POOLING = 'session'.freeze

      # Server connection is assigned to client only during a transaction. When
      # PgBouncer notices that transaction is over, the server will be put back
      # into pool. This mode breaks few session-based features of PostgreSQL.
      # You can use it only when application cooperates by not using features
      # that break. See the table below for incompatible features.
      TRANSACTION_POOLING = 'transaction'.freeze

      # Most aggressive method. This is transaction pooling with a twist -
      # multi-statement transactions are disallowed. This is meant to enforce
      # "autocommit" mode on client, mostly targeted for PL/Proxy.
      STATEMENT_POOLING = 'statement'.freeze

      POOLING_MODES = [SESSION_POOLING, TRANSACTION_POOLING, STATEMENT_POOLING]

      attr_reader :pooling_mode

      def initialize(pooling_mode, connection, logger, connection_parameters, config)
        @pooling_mode = pooling_mode
        super(connection, logger, connection_parameters, config)
      end

      # The PostgreSQL adapter sets a number of session level settings. In
      # transaction pooling mode, this will have undesirable results, since
      # each `SET` statement is not gauranteed to be executed with the same
      # backend connection.
      #
      # Instead, when using this adapter, you should set a connect_query that sets the following:
      #
      #   set client_encoding = 'UTF8'
      #   set client_min_messages = 'warning'
      #   set standard_conforming_strings = 'on'
      #   set timezone = 'UTC'
      #
      # See https://github.com/rails/rails/blob/a456acb2f2af8365eb9151c7cd2d5a10c189d191/activerecord/lib/active_record/connection_adapters/postgresql_adapter.rb#L648-L678
      def configure_connection
        if pooling_mode == TRANSACTION_POOLING || pooling_mode == STATEMENT_POOLING
          # NOOP
        else
          super
        end
      end
    end
  end
end
