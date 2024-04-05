source 'https://rubygems.org'
ruby '2.4.0'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 7.0.8', '>= 7.0.8.1'
# Use SCSS for stylesheets
gem 'sass-rails', '>= 5.0.8'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier'
# Postgres default
gem 'pg'
# Use jquery as the JavaScript library
gem 'jquery-rails', '>= 4.3.2'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'

# Git hosted gems
gem 'csv2json', git: 'https://github.com/theodi/csv2json.git'
gem 'csv2rest', git: 'https://github.com/theodi/csv2rest.git'
gem 'alternate_rails', '~> 5.0.0', git: 'https://github.com/theodi/alternate-rails.git'
gem 'grape-swagger-rails', git: 'https://github.com/pezholio/grape-swagger-rails.git', branch: 'change-layout-test-branch'

# Current version not rails 5 or ruby 2.4 compatible
gem 'csvlint', git: 'https://github.com/jamesjefferies/csvlint.rb.git', branch: 'ruby-2.4-rails-5.0-compatibility'

# New way of validating schemas
gem 'jsontableschema'

# User related
gem 'omniauth-github', '>= 1.3.0'


# Bootstrap and view stuff
gem 'bootstrap-sass', '~> 3.2.0'
gem 'font-awesome-sass'
gem 'autoprefixer-rails'
gem 'rails-bootstrap-helpers'
gem 'bootstrap-select-rails'
gem 'bootstrap_form'
gem "bootstrap-table-rails"

# Logging and debug
gem 'awesome_print'

# API functionality
gem 'grape', '>= 0.19.2'
gem 'grape-route-helpers', '>= 2.1.0'
# There are breaking changes in 0.26.1 so freeze here for now
gem 'grape-swagger', '0.26.1'
gem 'grape-swagger-entity', '~> 0.2.0'

# Markdown processing, rendering & syntax highlighting
gem 'redcarpet'
gem 'rouge'
gem 'coderay'

# Exception handling
gem 'airbrake'

# External services
gem 'twitter'
gem 'octokit'
gem 'git'
gem 'odlifier'
gem 'aws-sdk', '~> 2'
gem 'pusher'
gem 'certificate-factory'

# Queues
gem 'sidekiq', '>= 5.0.0'

# General stuff
gem 'open_uri_redirections'
gem 'dotenv-rails', '>= 2.7.6'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', '~> 1.0.0'
end

group :development do
  gem 'pry-remote'
  gem 'letter_opener'
  gem 'term-ansicolor'
  gem 'annotate'
  gem 'better_errors', '>= 2.2.0'
  gem 'binding_of_caller'

  # Adds some nice rake tasks for generating migrations
  gem 'lol_dba', '>= 2.1.2'
end

group :development, :test do
  gem 'lograge', '>= 0.9.0'
  gem 'bundler-audit'

  # Spring speeds up development by keeping your application running
  # in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'guard'
  gem 'guard-rspec', require: false
  gem 'guard-rails', require: false
  gem 'terminal-notifier-guard', '~> 1.6.1'
end

group :test do
  gem 'database_cleaner'
  gem 'rspec-rails', '>= 3.6.0'
  gem 'pry'
  gem 'poltergeist', '>= 1.15.0'
  gem 'faker'
  gem 'factory_girl_rails', '>= 4.9.0'
  gem 'coveralls', '~> 0.8.20'
  gem 'vcr'
  gem 'webmock'
  gem 'foreman'
  # Rails 5 has pulled out 'assigns' - this puts it back
  gem 'rails-controller-testing', '>= 1.0.3'
end

group :production do
  gem 'rails_12factor'
  gem 'puma'
end
