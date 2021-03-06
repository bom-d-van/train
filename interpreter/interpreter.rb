require "socket"

class Interpreter
  SOCKET_NAME = "/tmp/train.interpreter.socket"

  def self.run
    server = listen

    loop {
      client = server.accept
      format, option, content = read_all(client)

      begin
        result = self.send("render_#{format}", content, option)
        client.write "success<<#{result}"
      rescue => e
        puts e
        client.write "error<<#{e}"
      end
      client.close
    }
  end

  private
  def self.listen
    begin
      `rm -f #{SOCKET_NAME}`
      server = UNIXServer.new(SOCKET_NAME)
      puts "<<ready"
      `touch #{SOCKET_NAME}`
      server
    rescue => e
      puts e
      exit 1
    end
  end


  def self.read_all client
    data = ""
    recv_length = 2000
    while tmp = client.recv(recv_length)
      data += tmp
      break if tmp.length < recv_length
    end
   data.split("<<")
  end

  def self.render_sass content, option
    _render_sass(content, :sass, option)
  end

  def self.render_scss content, option
    _render_sass(content, :scss, option)
  end

  def self._render_sass content, syntax, option
    require "sass"

    options = {
      :load_paths => ["assets/stylesheets"],
      :syntax => syntax
    }

    options[:debug_info] = true if option == "debug_info"
    options[:line_numbers] = true if option == "line_numbers"

    engine = Sass::Engine.new(content, options)
    engine.render
  end

  def self.render_coffee content, option
    require "coffee-script"
    CoffeeScript.compile content
  end
end

Interpreter.run
