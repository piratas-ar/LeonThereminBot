# frozen_string_literal: true
set :application, 'LeonThereminBot'
set :repo_url, 'https://github.com/piratas-ar/LeonThereminBot'

set :bundle_flags, '--deployment'
set :default_env, path: '/usr/lib/passenger/bin:$PATH'

set :linked_files, %w{.env}

namespace :deploy do
  desc "Set webhook"
  task :set_webhook do
    on primary :app do
      within release_path do
        execute :rake, 'telegram:bot:set_webhook'
      end
    end
  end
end
