require 'active_record/connection_adapters/postgresql_adapter'

module ActiveRecord
  module ConnectionHandling
    VALID_CONN_PARAMS = [:host, :hostaddr, :port, :dbname, :user, :password, :connect_timeout,
                         :client_encoding, :options, :application_name, :fallback_application_name,
                         :keepalives, :keepalives_idle, :keepalives_interval, :keepalives_count,
                         :tty, :sslmode, :requiressl, :sslcompression, :sslcert, :sslkey,
                         :sslrootcert, :sslcrl, :requirepeer, :krbsrvname, :gsslib, :service]

    # Establishes a connection to the database that's used by all Active Record objects
    def pgbouncer_connection(config)
      conn_params = config.symbolize_keys
      raise 'Prepared statements cannot be used with pgbouncer in transaction pooling mode' if conn_params[:pooling_mode] == 'transaction' && conn_params[:prepared_statements]
      raise 'Session level variables cannot be used with pgbouncer in transaction pooling mode' if conn_params[:pooling_mode] == 'transaction' && conn_params[:variables]

      conn_params.delete_if { |_, v| v.nil? }

      # Map ActiveRecords param names to PGs.
      conn_params[:user] = conn_params.delete(:username) if conn_params[:username]
      conn_params[:dbname] = conn_params.delete(:database) if conn_params[:database]

      # Forward only valid config params to PGconn.connect.
      conn_params.keep_if { |k, _| VALID_CONN_PARAMS.include?(k) }

      # The postgres drivers don't allow the creation of an unconnected PGconn object,
      # so just pass a nil connection object for the time being.
      ConnectionAdapters::PgBouncerAdapter.new(nil, logger, conn_params, config)
    end
  end
end

module ActiveRecord
  module ConnectionAdapters
    class PgBouncerAdapter < PostgreSQLAdapter
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
        # NOOP
      end
    end
  end
end
