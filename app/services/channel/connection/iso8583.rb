module Channel
  module Connection
    module Iso8583

      DEFAULT_OPTIONS = {
        header_length: 0,
        read_timeout: ENV['DEFAULT_TIMEOUT'].to_i
      }

      def self.send(host, port, message, options={})
        options.reverse_merge!(DEFAULT_OPTIONS)
        socket = TCPSocket.new(host, port)
        response = send_to_socket(socket, message, options)
      ensure
        socket.close if socket
      end

      private

      def self.send_to_socket(socket, message, options={})
        socket.send(message, 0)

        if IO.select([socket], nil, nil, options[:read_timeout])
          bit1 = socket.readpartial(1) # get first digit response
          bit2 = socket.readpartial(1) # get second digit response
          message_length = "#{bit1.ord}".to_i * 256 + "#{bit2.ord}".to_i - options[:header_length].to_i
          socket.readpartial(message_length) # get all message
        else
          # IO.select returns nil when the socket is not ready before timeout
          # seconds have elapsed
          raise Exceptions::SocketConnectionTimeout.new
        end
      end
    end
  end
end
