source "https://rubygems.org"
git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

gemspec
gem 'activesupport', '~> 3.1.0'
gem 'activerecord',  '~> 3.1.0'
gem "sqlite3", "~> 1.3.6"
