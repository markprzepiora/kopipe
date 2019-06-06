source "https://rubygems.org"
git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

gemspec
gem 'activesupport', '~> 5.2.3'
gem 'activerecord',  '~> 5.2.3'
gem "sqlite3", "~> 1.3.6"
