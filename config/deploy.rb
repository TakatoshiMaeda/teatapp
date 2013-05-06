require "bundler/capistrano"
require "capistrano/nginx/tasks"

default_run_options[:pty] = true

set :user_name, "" #nodes/jsonのid値を指定します
set :server_address, "" #作成したサーバーのIPアドレス/ドメインを指定します

set :application, "testapp"
set :repository,  "https://github.com/TakatoshiMaeda/teatapp.git"
set :scm, :git
set :git_salow_clone, 1

role :web, server_address
role :app, server_address
role :db,  server_address, :primary => true
role :db,  server_address

# nginx config
set :ngx_app_port, 80
set :ngx_server_name, server_address

set :user, user_name
set :runner, user_name
set :group, user_name
set :use_sudo, false

set :root_path, "/home/#{user_name}/#{application}"
set :deploy_via, :remote_cache
set :deploy_to, "#{root_path}"
set :shared_path, "#{root_path}/shared"

set :gemfile, "BUNDLE_GEMFILE=#{current_path}/Gemfile"
set :unicorn, "bundle exec unicorn_rails"
set :unicorn_config, "#{current_path}/config/unicorn.rb"
set :unicorn_pid, "#{shared_path}/pids/unicorn.pid"

namespace :deploy do
  task :start, :roles => :app, :except => { :no_release => true } do
    cmd = "cd #{current_path}"
    cmd << " && #{gemfile}"
    cmd << " #{unicorn}"
    cmd << " -c #{unicorn_config}"
    cmd << " -D"
    run cmd
  end
  task :stop, :roles => :app, :except => { :no_release => true } do
    run "kill `cat #{unicorn_pid}`"
  end
  task :oldstop, :roles => :app, :except => { :no_release => true } do
    run "kill -s QUIT `cat #{unicorn_pid}`"
  end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "kill -s USR2 `cat #{unicorn_pid}`"
  end
  task :refresh, :roles => :app, :except => { :no_release => true } do
    stop
    start
  end
end
