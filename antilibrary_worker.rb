# encoding: utf-8
#
# Settings:
# ---------
#
# Set IPFS_BIN_PATH with the full path to your ipfs bin file (it cannot be a relative path)
# Windows example: 
# IPFS_BIN_PATH = 'C:/go-ipfs/ipfs.exe'
# Linux example:
IPFS_BIN_PATH = './ipfs'


# -------------------------------------------------------------------------

#require 'pry'
require 'open3'
require 'net/http'
require 'json'
require 'base64'
require 'fileutils'
require 'optparse'

VERSION = '0.1'
TRACKER_ID = 'QmfYZKUBCrHhLfE5mrG48hQ2wHGSNKzRfS4QoaCFhbWYCf'

ARGV << '-h' if ARGV.empty?

options = {}
OptionParser.new do |opt|
  opt.on('--storage-limit XXgb', 'Total size (in GB) your ipfs repository can use') {|o| options[:storage_limit] = o}
  opt.on('--nickname NICKNAME', 'Pick any nickname for your node (you must let me know what nickname you pick)') {|o| options[:nickname] = o}
  opt.on('--secret_keyword KEYWORD', 'Secret keyword. This is used as a temporary hack for the ipfs pubsub lack of', 'authentication (you must let me know what secret keyword you pick)') {|o| options[:secret_keyword] = o}

  opt.set_banner <<-EOF
  Antilibrary.bit Worker v#{VERSION}

  Usage: ruby al_worker.rb [options]
  EOF

  opt.separator <<-EOF
  
  Eg: ruby al_worker.rb --storage-limit=1000GB --nickname=i_seed_books --secret_keyword=MyVerYSecreTkeyWORD

  How to access antilibrary: http://telegra.ph/Antilibrarybit-06-07
  Latest version of this client: https://www.reddit.com/r/antilibrary/
  Feedback to: antilibrary@protonmail.com OR https://www.reddit.com/user/antilibrary/ OR #antilibrary (EFnet/Freenode)
  EOF
end.parse!


if options.length < 3
  puts "Missing parameters. Please run 'ruby al_worker.rb -h' to see all required parameters."
  exit
end


def unhandled_exception(message)
  puts "##################################"
  puts "Something unexpected happened! Please send me a message with this error message."
  puts "ERROR MESSAGE: #{message}"
  puts "##################################"
  exit
end


def message_tracker(message)
  message_json = JSON.generate(message)
  uri = URI("http://localhost:5001/api/v0/pubsub/pub?arg=#{TRACKER_ID}&arg=#{message_json}")
  Net::HTTP.start(uri.host, uri.port) do |http|
    request = Net::HTTP::Get.new uri
    http.request request
  end
end


def execute_ipfs_command(command, verbose=true)
  print "running: ipfs #{command.split(' ')[0, 2].join(' ')} > " if verbose
  stdout, stdeerr, status = Open3.capture3("#{IPFS_BIN_PATH} --enc=json #{command}")

  if !status.success?
    #puts "FAILED"
    output = stdeerr
  else
    #puts "SUCCESS"
    output = stdout
  end
  puts "[OK]" if verbose
  return output
end


#check if ipfs bin exists
if !File.exist?(IPFS_BIN_PATH)
  puts "Error - IPFS binary not found!"
  puts "You need to install IPFS in order to use this worker (https://ipfs.io/docs/install/)"
  puts "Please set the variable IPFS_BIN_PATH inside this script."
  puts "The IPFS_BIN_PATH must point to your ipfs bin file."
  puts "On linux it can be something like IPFS_BIN_PATH='ipfs'"
  puts "On windows the full path may be required IPFS_BIN_PATH='C:/go-ipfs/ipfs.exe'"
  exit
end

# check if daemon is running with pubsub enabled 
stdout, stdeerr, status = Open3.capture3("#{IPFS_BIN_PATH} pubsub pub test test")
if !status.success?
  puts "Error"
  if stdeerr.include?("Error: experimental pubsub feature not enabled.")
    puts "You're running the ipfs daemon without the experimental pubsub feature."
    puts "Please run the daemon with: ipfs daemon --enable-pubsub-experiment"

  elsif stdeerr.include?("Error: This command must be run in online mode.") or stdeerr.include?("api not running")
    puts "It seems that you're not running the ipfs daemon."
    puts "Please run the daemon in a different shell: ipfs daemon --enable-pubsub-experiment"

  elsif stdeerr.include?("Error: no IPFS repo found")
    puts "It seems that this is the first time you're running IPFS."
    puts "Please initialize an ipfs repository by running 'ipfs init' then rerun this script."

  else
    unhandled_exception(stdeerr)
  end

  exit
end

puts "Starting worker..."

WORKER_NICKNAME = options[:nickname]
SECRET_KEYWORD = options[:secret_keyword]

@local_space_limit = options[:storage_limit].gsub(/gb/i, '').to_i*1024*1024*1024

# get space currently used
print "Getting local ipfs repo stat (this may take a while)..."
stdout, stdeerr, status = Open3.capture3("#{IPFS_BIN_PATH} repo stat")
if !status.success?
  unhandled_exception(stdeerr)
else
  @local_space_used = stdout.split(/\n/)[1].split(/\t/).last.strip.to_i
end
puts "[DONE]"


#get worker ipfs id
stdout, stdeerr, status = Open3.capture3("#{IPFS_BIN_PATH} id")
if !status.success?
  unhandled_exception(stdeerr)
end
@worker_id = JSON.parse(stdout)['ID']

puts
puts "Starting node with the following settings (Make sure you've sent me this information - /u/antilibrary):"
puts "  Node nickname: #{WORKER_NICKNAME}"
puts "  Node ID: #{@worker_id}"
puts "  Secret keyword: #{SECRET_KEYWORD}"
puts

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

def listener
  send_joining
  puts "Listening on: #{@worker_id}#{SECRET_KEYWORD} (keep this secret)"
  uri = URI("http://localhost:5001/api/v0/pubsub/sub?arg=#{@worker_id}#{SECRET_KEYWORD}")
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

          command = data.split(':').first
          ipfs_hash = data.split(':').last

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

while true
  begin
    listener
  rescue => e
    puts "#{e} >> Restarting... (timeouts are expected - anything else is not)"
  end
end