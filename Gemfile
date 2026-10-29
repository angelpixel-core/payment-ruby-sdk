# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "minitest", ">= 5.20", "< 7"
gem "rake", "~> 13.0"

group :development, :test do
  gem "bundler-audit", require: false
  gem "standard"
  gem "webrick", "~> 1.8" # required by `yard server` on Ruby >= 3.0
  gem "yard", "~> 0.9"
end
