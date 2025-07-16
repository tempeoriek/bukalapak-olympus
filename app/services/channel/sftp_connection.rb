require 'net/sftp'
require 'stringio'

module Channel
  class SftpConnection

    def initialize(config)
      @host = config[:host]
      @port = config[:port]
      @user = config[:user]
      @password = config[:password]
      @private_key = config[:private_key]
    end

    # send explicit file
    def send_file(source, destination)
      options = {
        password: @password
      }
      options[:port] = @port unless @port.nil?
      Net::SFTP.start(@host, @user, options) do |sftp|
        # upload a file or directory to the remote host
        io = StringIO.new(source)
        sftp.upload!(io, destination)
      end

      Time.now
    end

    # connect to sftp and create the file remotely
    def send_remote_file(content, destination)
      Net::SFTP.start(@host, @user, :port => 3333, :password => @password) do |sftp|
        # open and write to a pseudo-IO for a remote file
        sftp.file.open(destination, "w") do |f|
          f.puts(content)
        end
      end
    end

    # connect to sftp and create the file remotely, using pub-key
    def send_remote_file_with_pkey(content, destination)
      options = {
        key_data: [ @private_key ],
        keys: [],
        keys_only: true
      }

      Net::SFTP.start(@host, @user, options) do |sftp|
        sftp.file.open(destination, "w") do |f|
          f.puts(content)
        end
      end

      Time.now
    end
  end
end
