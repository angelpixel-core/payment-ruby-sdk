# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "lib" << "test"
  t.test_files = FileList["test/**/*_test.rb"]
  t.warning = true
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

task default: :test
