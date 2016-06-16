require 'spec_helper'

describe ActiveRecord::PgBouncer do
  describe '#pgbouncer_connection' do
    it 'opens a connection' do
      # This gets called by https://github.com/rails/rails/blob/31ab3aa0e881acfd1475abae602455905a4cadf1/activerecord/lib/active_record/connection_adapters/postgresql_adapter.rb#L577
      allow_any_instance_of(PG::Connection).to receive(:async_exec).with('SELECT oid, typname, typelem, typdelim, typinput FROM pg_type').and_call_original

      # This gets called by https://github.com/rails/rails/blob/31ab3aa0e881acfd1475abae602455905a4cadf1/activerecord/lib/active_record/connection_adapters/postgresql_adapter.rb#L578
      allow_any_instance_of(PG::Connection).to receive(:async_exec).with('SHOW TIME ZONE').and_call_original

      ActiveRecord::Base.pgbouncer_connection({
        dbname: 'pgbouncer_test',
        pooling_mode: 'transaction'
      })
    end

    it 'raises an error when variables are provided in transaction pooling mode' do
      expect do
        ActiveRecord::Base.pgbouncer_connection({
          dbname: 'pgbouncer_test',
          pooling_mode: 'transaction',
          variables: {
            statement_timeout: 15000,
          }
        })
      end.to raise_error 'Session level variables cannot be used with pgbouncer in transaction pooling mode'
    end

    it 'raises an error when prepared_statements are enabled in transaction pooling mode' do
      expect do
        ActiveRecord::Base.pgbouncer_connection({
          dbname: 'pgbouncer_test',
          pooling_mode: 'transaction',
          prepared_statements: true
        })
      end.to raise_error 'Prepared statements cannot be used with pgbouncer in transaction pooling mode'
    end
  end
end
