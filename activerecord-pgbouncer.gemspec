# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active_record/pgbouncer/version'

Gem::Specification.new do |spec|
  spec.name          = "activerecord-pgbouncer"
  spec.version       = ActiveRecord::PgBouncer::VERSION
  spec.authors       = ["Eric J. Holmes"]
  spec.email         = ["eric@remind101.com"]

  spec.summary       = %q{ActiveRecord connection adapter for safe PgBouncer use}
  spec.description   = %q{ActiveRecord connection adapter for safe PgBouncer use}
  spec.homepage      = "https://github.com/remind101/activerecord-pgbouncer"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", [">= 4.1", "<= 5"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
