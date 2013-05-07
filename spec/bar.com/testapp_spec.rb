require 'spec_helper'

server_name = ""
app_name = "testapp"

describe 'nginx' do
  it { should be_enabled   }
  it { should be_running   }
end

describe 'port 80' do
  it { should be_listening }
end

describe "/etc/nginx/sites-enabled/#{app_name}" do
  it { should be_file }
  it { should contain "listen 80 default deferred;" }
  it { should contain "server_name #{server_name};" }
  it { should contain "server unix:/tmp/#{app_name}.sock fail_timeout=0;" }
  it { should contain "upstream #{app_name}" }
end

