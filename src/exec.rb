require 'net/ssh'
require 'yaml'

def exec_command(channel, command)
  puts "executing: '#{command}'"
  channel.exec(command)
  # Wait for response
  channel.wait
end

begin
  puts 'サーバーにyum updateをかけるよ'

  config_dir = "#{__dir__}/../config"

  # 設定ファイルのリストを取得
  settings = Dir.open(config_dir).sort

  puts '設定ファイルを選んでちょ'
  puts '---------------------------'
  settings.each do |path|
    next if path == '.' || path == '..'
    if path =~ /.+\.yml\Z/
      puts path.downcase.gsub(/.yml/, "")
    end
  end
  puts '---------------------------'
  puts 'Setting: '

  setting = STDIN.gets.chomp + ".yml"
  config = YAML.load_file("#{config_dir}/#{setting}")

  servers = config['servers']

  servers.each do |server|

    puts 'starting...'
    pp server

    hostname = server['host']
    port = server['port']
    username = server['user']
    password = server['password']
    sudo_password = server['sudo_password']
    key = server['key']
    result = ''

    Net::SSH.start( hostname, username, :keys => key, :password => password, :port => port ) do |ssh|

      channel = ssh.open_channel do |channel, success|
        channel.on_data do |channel, data|
          if data =~ /^\[sudo\]/
            # Send the password
            channel.send_data "#{sudo_password}\n"
          else
            # Store the data
            result += data.to_s
          end
        end
        # Request a pseudo TTY
        channel.request_pty
        # Execute the command
        exec_command(channel, 'sudo yum -y update')

      end
      # Wait for opened channel
      channel.wait
      puts result
    end
  end

  exit 0

rescue => e
  pp e
  pp e.backtrace

  exit 1
end