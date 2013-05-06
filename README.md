# Webアプリデプロイサンプルアプリ

https://github.com/TakatoshiMaeda/webserver-cookbooks の続きです。    
Webサーバーのconfigと共にアプリをデプロイして、サーバーに一度もログインせずアプリの追加を行います。  

## 設定変更

`config/deploy.rb`を2箇所編集します。  

```ruby
# config/deploy.rb
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
set :app_port, 80
set :server_name, server_address

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
```

編集が終わったらデプロイです。  

## デプロイ
以下のコマンドを実行して下さい。

```bash
bundle install --path=./vendor
bundle exec cap deploy:setup
bundle exec cap deploy
bundle exec cap deploy:start
bundle exec cap nginx:setup
bundle exec cap nginx:reload
```
これでサーバーのトップページにアクセスをすると`Hello ChefSolo!`が表示されます。  

capistrano-nginxをインストールすると、config/deploy/nginx_conf.erbが/etc/nginx/sites-enabled/にデプロイされます。  
アプリケーション毎に作成されるので、アプリの追加時には同様の設定をデプロイしていけばWebサーバーはノータッチでアプリの追加ができます。

## サーバーテスト

最後にデプロイした設定がサーバーに正しく反映されているか確認をします。  
まずはspec/bar.com/testapp_spec.rbを編集します。
```ruby
# spec/bar.com/testapp_spec.rb
require 'spec_helper'

server_name = "" #ここにdeproy.rbのset :server_addressと同じ値を設定する
app_name = "testapp"

describe 'nginx' do
  it { should be_installed }
  it { should be_enabled   }
  it { should be_running   }
end

describe 'port 80' do
  it { should be_listening }
end

describe '/etc/nginx/sites-enabled/testapp' do
  it { should be_file }
  it { should contain "listen 80 default deferred;" }
  it { should contain "server_name #{server_name};" }
  it { should contain "server unix:/tmp/#{app_name}.sock fail_timeout=0;" }
  it { should contain "upstream #{app_name}" }
end

describe "/tmp/#{app_name}.sock" do
  it { should be_file }
end
```
設定し終わったら、以下のコマンドを実行して下さい。  
```bash
mv spec/bar.com spec/サーバーIPorホスト名
SUDO_PASSWORD=***** bundle exec rake spec #*****には設定したパスワードを指定して下さい
```
全てグリーンになるはずです。  
このテストで、サーバー上でアプリが動作するために必要な設定が適用されていることを確認できました。  
  
サーバーにノータッチでデプロイ/設定/テストが出来るのももちろんですが、ひとつのリポジトリにこれらすべての情報が集約されるのは嬉しいですね！