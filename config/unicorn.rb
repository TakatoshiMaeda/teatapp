app_name = "testapp"
root_path = "/home/tmaeda/#{app_name}/current"
shared_path = "/home/tmaeda/#{app_name}/shared"
listen "/tmp/#{app_name}.sock"
 
stderr_path "#{shared_path}/log/unicorn.stderr.log"
stdout_path "#{shared_path}/log/unicorn.stdout.log"
 
worker_processes 2
 
preload_app true
 
before_fork do |server, worker|
  old_pid = "#{server.config[:pid]}.oldbin"
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
 
    end
  end
end