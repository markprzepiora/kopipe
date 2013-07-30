require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

activerecord_version = ENV["AR"]

if activerecord_version
  task :default => :versioned_spec
else
  task :default => :spec
end

task :set_gemfile do
  if activerecord_version
    rm "Gemfile.lock", force: true
    cp "Gemfile-activerecord-#{activerecord_version}", "Gemfile"
    sh "bundle install"
  end
end

task :versioned_spec => :set_gemfile do
  ENV["AR"] = nil
  sh "bundle exec rake"
end

task :all do
  versions = %w{ 3.1.x 3.2.x 4.0.x }

  versions.each do |version|
    # ENV["AR"] = activerecord_version
    sh "AR=#{version} rake"
  end
end
