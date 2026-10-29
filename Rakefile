# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "lib" << "test"
  t.test_files = FileList["test/**/*_test.rb"].exclude("test/integration/**/*_test.rb")
  t.warning = true
end

namespace :test do
  Rake::TestTask.new(:integration) do |t|
    t.libs << "lib" << "test"
    t.test_files = FileList["test/integration/**/*_test.rb"]
    t.warning = true
  end
end

desc "Run integration tests against Payment Sandbox container"
task integration: "test:integration"

begin
  require "standard/rake"
rescue LoadError
  desc "Run StandardRB linter (requires the standard gem)"
  task :standard do
    abort "standard is not installed. Run `bundle install` first."
  end
end

begin
  require "bundler/audit/task"
  Bundler::Audit::Task.new
  desc "Alias for bundle:audit"
  task audit: "bundle:audit"
rescue LoadError
  desc "Run bundler-audit security check (requires the bundler-audit gem)"
  task :audit do
    abort "bundler-audit is not installed. Run `bundle install` first."
  end
end

begin
  require "yard"

  YARD::Rake::YardocTask.new(:yard) do |t|
    t.options = ["--fail-on-warning"]
  end
rescue LoadError
  desc "Generate YARD documentation (requires the yard gem)"
  task :yard do
    abort "yard is not installed. Run `bundle install` first."
  end
end

task default: %i[test standard]
