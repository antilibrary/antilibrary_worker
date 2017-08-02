# encoding: utf-8
#
# Antilibrary Worker
# Latest version of this client on https://github.com/antilibrary/antilibrary_worker

#require 'pry'
require 'open3'
require 'net/http'
require 'json'
require 'base64'
require 'fileutils'
require 'optparse'
require 'yaml'

VERSION = '0.3'
TRACKER_ID = 'QmfYZKUBCrHhLfE5mrG48hQ2wHGSNKzRfS4QoaCFhbWYCf'

def create_config
  # create new config file
  file_content = <<EOF
# IPFS binary path
# Set ipfs_bin_path with the full path to your ipfs bin file (it cannot be a relative path)
# Windows example: 
# ipfs_bin_path = 'C:/go-ipfs/ipfs.exe'
# Linux example:
ipfs_bin_path: './go-ipfs/ipfs'

# Total size (in GB) your ipfs repository can use
storage_limit: 100

# Pick any nickname for your node (you must let me know what nickname you pick)
nickname: my_node_1

# Secret keyword. This is used as a temporary hack for the ipfs pubsub lack of
# authentication (you must let me know what secret keyword you pick)
secret_keyword: MyVerYSecreTkeyWORD
EOF
  File.open("#{File.expand_path(File.dirname(__FILE__))}/config.yml", 'w') {|f| f.write file_content }
  warn "Please edit the file config.yml and set your settings"
  warn " "
  abort
end

if !File.exists?("#{File.expand_path(File.dirname(__FILE__))}/config.yml")
  create_config
end

# load config
@config = YAML::load_file("#{File.expand_path(File.dirname(__FILE__))}/config.yml")

# check if default config has not been changed
if @config['nickname'] == 'my_node_1' or @config['secret_keyword'] == 'MyVerYSecreTkeyWORD'
  create_config
end

def unhandled_exception(message)
  warn "##################################"
  warn "Something unexpected happened! Please send me a message with this error message."
  warn "ERROR MESSAGE: #{message}"
  warn "##################################"
  abort
end

def restart_local_daemon
  warn " "
  warn "Connection with the IPFS daemon lost. Restarting daemon..."
  stdout, stdeerr, status = Open3.capture3("nohup #{@config['ipfs_bin_path']} daemon &")
  if !status.success?
    unhandled_exception(stdeerr)
  end
end

#check if ipfs bin exists
if !File.exist?(@config['ipfs_bin_path'])
  warn "Error - IPFS binary not found!"
  warn "You need to install IPFS in order to use this worker (https://ipfs.io/docs/install/)"
  warn "Please set the variable ipfs_bin_path inside the config.yml"
  warn "The ipfs_bin_path must point to your ipfs bin file."
  warn "On linux it can be something like ipfs_bin_path: 'ipfs'"
  warn "On windows the full path may be required ipfs_bin_path: 'C:/go-ipfs/ipfs.exe'"
  abort
end

# check if daemon is running with pubsub enabled 
stdout, stdeerr, status = Open3.capture3("#{@config['ipfs_bin_path']} --api /ip4/#{ENV['ipfs_api_addr']}/tcp/5001 pubsub pub test test")
if !status.success?
  warn "Error - IPFS pubsub not enabled"
  if stdeerr.include?("Error: experimental pubsub feature not enabled.")
    warn "You're running the ipfs daemon without the experimental pubsub feature."
    warn "Please run the daemon with: ipfs daemon --enable-pubsub-experiment"

  elsif stdeerr.include?("Error: This command must be run in online mode.") or stdeerr.include?("api not running")
    warn "It seems that you're not running the ipfs daemon."
    warn "Please run the daemon in a different shell: ipfs daemon --enable-pubsub-experiment"

  elsif stdeerr.include?("Error: no IPFS repo found")
    warn "It seems that this is the first time you're running IPFS."
    warn "Please initialize an ipfs repository by running 'ipfs init' then rerun this script."

  else
    unhandled_exception(stdeerr)
  end

  abort
end


# set parameters
WORKER_NICKNAME = @config['nickname']
SECRET_KEYWORD = @config['secret_keyword']
@local_space_limit = @config['storage_limit'].to_s.gsub(/gb/i, '').to_i*1024*1024*1024


# get worker ipfs id
stdout, stdeerr, status = Open3.capture3("#{@config['ipfs_bin_path']} --api /ip4/#{ENV['ipfs_api_addr']}/tcp/5001 id")
if !status.success?
  unhandled_exception(stdeerr)
end
@worker_id = JSON.parse(stdout)['ID']

puts
puts "Starting Antilibrary worker with the following settings (Make sure you've sent me this information - /u/antilibrary):"
puts "  Node nickname: #{WORKER_NICKNAME}"
puts "  Node ID: #{@worker_id}"
puts "  Secret keyword: #{SECRET_KEYWORD}"
puts

puts "Listening on: #{@worker_id}#{SECRET_KEYWORD} (keep this secret)"

# get space currently used
print "Getting local ipfs repo stat (this may take a while)..."
stdout, stdeerr, status = Open3.capture3("#{@config['ipfs_bin_path']} repo stat")
if !status.success?
  restart_local_daemon
else
  @local_space_used = stdout.split(/\n/)[1].split(' ').last.strip.to_i
end
puts "[DONE]"

def listener
  send_joining
  uri = URI(URI.encode("http://#{ENV['ipfs_api_addr']}:5001/api/v0/pubsub/sub?arg=#{@worker_id}#{SECRET_KEYWORD}"))
  Net::HTTP.start(uri.host, uri.port) do |http|
    @http = http
    @http.read_timeout = 120
    request = Net::HTTP::Get.new uri

    @http.request request do |response|
      response.read_body do |chunk|
        msg = JSON.parse(chunk)
        if msg != {}
          data = Base64.decode64(msg["data"])

          print "(#{Time.now.strftime('%H:%M:%S')}) (#{(@local_space_used.to_f/1024/1024/1024).round(2)} of #{(@local_space_limit.to_f/1024/1024/1024).round(2)}gb used) Got message: #{data} >> "

          command, ipfs_hash = data.split(':', 2)

          #prepare response message
          new_message = Hash.new
          new_message['worker_nickname'] = WORKER_NICKNAME
          new_message['command'] = command
          new_message['ipfs_hash'] = ipfs_hash
          new_message['local_space_used'] = @local_space_used


          case command

            when "pin"
              # check if space limit is not overrun
              if @local_space_used < @local_space_limit.to_i

                # get file info
                file_info = execute_ipfs_command("file ls --timeout 30s #{ipfs_hash}", false)

                # if file is not in the ipfs network
                if file_info.include?('Error: request canceled')
                  puts "[SKIP]"
                  new_message['response'] = file_info

                else

                  file_size = JSON.parse(file_info)['Objects'].first[1]['Size']
                  # calculate timeout: (filesize converted from b to kb)/(main seed node speed in kbit/s)+20
                  timeout_delay = (file_size/1024)/(3072/8)+20

                  new_message['response'] = execute_ipfs_command("pin add --timeout #{timeout_delay}s  #{ipfs_hash}", true)
                  if !new_message['response'].include?("Error")
                    @local_space_used += JSON.parse(execute_ipfs_command("object stat  #{ipfs_hash}", false))['CumulativeSize']
                  end
                end

              else
                puts "Storage limit reached! Not accepting new files."
                new_message['response'] = "No space left!"
              end

              new_message['local_space_used'] = @local_space_used
              message_tracker(new_message)

            when "unpin"
              @local_space_used -= JSON.parse(execute_ipfs_command("object stat  #{ipfs_hash}", false))['CumulativeSize']
              new_message['response'] = execute_ipfs_command("pin rm #{ipfs_hash}", true)
              new_message['local_space_used'] = @local_space_used
              message_tracker(new_message)

            when "check"
              new_message['response'] = execute_ipfs_command("pin ls --type=recursive #{ipfs_hash}", true)

              message_tracker(new_message)

            when "list_all"
              new_message['response'] = execute_ipfs_command("pin ls --type=recursive", true)

              # replace output with ipfs file url
              File.open("list_all.temp", 'w') {|file| file.write(new_message['response'])}
              new_message['response'] = execute_ipfs_command("add -q list_all.temp", true)
              message_tracker(new_message)
              FileUtils.rm("list_all.temp")

            when "ping"
              puts "sending pong!"
              new_message['response'] = "pong"
              message_tracker(new_message)

            when "joining"
              puts "Got ACK from tracker!"

            else
              puts "Command not recognized!"
          end
        end
      end
    end
  end
end

def send_joining
  # Send joining message to tracker
  print "Sending handshake message to tracker..."
  new_message = Hash.new
  new_message['worker_nickname'] = WORKER_NICKNAME
  new_message['command'] = 'joining'
  new_message['storage_limit'] = @local_space_limit
  new_message['local_space_used'] = @local_space_used
  message_tracker(new_message)
  puts "[DONE]"
end

def message_tracker(message)
  message_json = JSON.generate(message)
  uri = URI(URI.encode("http://#{ENV['ipfs_api_addr']}:5001/api/v0/pubsub/pub?arg=#{TRACKER_ID}&arg=#{message_json}"))
  Net::HTTP.start(uri.host, uri.port) do |http|
    request = Net::HTTP::Get.new uri
    http.request request
  end
end

def execute_ipfs_command(command, verbose=true)
  print "running: ipfs #{command.split(' ')[0, 2].join(' ')} > " if verbose
  stdout, stdeerr, status = Open3.capture3("#{@config['ipfs_bin_path']} --enc=json #{command}")

  if !status.success?
    output = stdeerr
  else
    output = stdout
  end
  puts "[OK]" if verbose
  return output
end


# main loop - avoid from existing on non critical error
loop {
  begin
    listener
  rescue => e

    if e.to_s.include?('Failed to open TCP connection to localhost:5001')
      restart_local_daemon

    elsif e.to_s.include?("Failed to open TCP connection to #{ENV['ipfs_api_addr']}:5001")
      warn " "
      warn "#################################################"
      warn "ERROR - IPFS Daemon is not running in the host machine"
      warn "Please run: 'ipfs daemon --enable-pubsub-experiment' in your computer (not inside the vagrant box)"
      warn "Once you have the daemon running, rerun the worker with: 'vagrant provision'"
      warn " "
      exit
    end

    puts "#{e} >> Restarting... (timeouts are expected - anything else is not)"
  end
}