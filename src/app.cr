require "option_parser"
require "./constants"
require "./models/two_factor"
require "base64"

module DoorCtrl
  # Server defaults
  port = DEFAULT_PORT
  process_count = DEFAULT_PROCESS_COUNT
  docs = nil
  docs_file = nil

  # Command line options
  OptionParser.parse(ARGV.dup) do |parser|
    parser.banner = "Usage: #{PROGRAM_NAME} [arguments]"

    parser.on("-p PORT", "--port=PORT", "Specifies the server port") { |p| port = p.to_i }

    parser.on("-w COUNT", "--workers=COUNT", "Specifies the number of processes to handle requests") do |w|
      process_count = w.to_i
    end

    parser.on("-r", "--routes", "List the application routes") do
      ActionController::Server.print_routes
      exit 0
    end

    parser.on("-v", "--version", "Display the application version") do
      puts "#{NAME} v#{VERSION}"
      exit 0
    end

    parser.on("-i ID", "--2fa=ID", "generates the 2fa QR code with the specified identifier") do |id|
      secret = ENV["TOTP_SECRET"]?
      if secret
        TwoFactor.print_totp_qr_code(id, secret)
      else
        puts "must configure 'TOTP_SECRET' ENV var"
      end
      exit 0
    end

    parser.on("-t", "--totp", "generates a totp secret") do
      puts "export TOTP_SECRET=#{TOTP.generate_base32_secret(32)}"
      exit 0
    end

    parser.on("-a", "--access", "generates a valid authorisation header") do
      secret = ENV["TOTP_SECRET"]?
      if secret
        code = TOTP.generate_number_string(secret)
        puts "Current code: #{code}"
        puts "Authorization: Basic #{Base64.strict_encode(":#{code}")}"
      else
        puts "must configure 'TOTP_SECRET' ENV var"
      end
      exit 0
    end

    parser.on("-c URL", "--curl=URL", "Perform a basic health check by requesting the URL") do |url|
      begin
        response = HTTP::Client.get url
        exit 0 if (200..499).includes? response.status_code
        puts "health check failed, received response code #{response.status_code}"
        exit 1
      rescue error
        error.inspect_with_backtrace(STDOUT)
        exit 2
      end
    end

    parser.on("-d", "--docs", "Outputs OpenAPI documentation for this service") do
      docs = ActionController::OpenAPI.generate_open_api_docs(
        title: NAME,
        version: VERSION,
        description: "App description for OpenAPI docs"
      ).to_yaml

      parser.on("-f FILE", "--file=FILE", "Save the docs to a file") do |file|
        docs_file = file
      end
    end

    parser.on("-h", "--help", "Show this help") do
      puts parser
      exit 0
    end
  end

  if docs
    File.write(docs_file.as(String), docs) if docs_file
    puts docs_file ? "OpenAPI written to: #{docs_file}" : docs
    exit 0
  end

  # Load the routes
  puts "Launching #{DoorCtrl::NAME} v#{DoorCtrl::VERSION}"
end

# Requiring config here ensures that the option parser runs before
# attempting to connect to databases etc.
require "./config"

module DoorCtrl
  server = ActionController::Server.new(port, "0.0.0.0")

  # (process_count < 1) == `System.cpu_count` but this is not always accurate
  # Clustering using processes, there is no forking once crystal threads drop
  server.cluster(process_count, "-w", "--workers") if process_count != 1

  {% if flag?(:win32) %}
    Process.on_interrupt do
      puts " > terminating gracefully"
      server.close
    end
  {% else %}
    terminate = Proc(Signal, Nil).new do |signal|
      puts " > terminating gracefully"
      spawn { server.close }
      signal.ignore
    end

    # Detect ctr-c to shutdown gracefully
    # Docker containers use the term signal
    Signal::INT.trap &terminate
    Signal::TERM.trap &terminate

    # Allow signals to change the log level at run-time
    # Turn on DEBUG level logging `kill -s USR1 %PID`
    register_severity_switch_signals
  {% end %}

  # Start the server
  server.run do
    server.socket.bind_tcp("::", port, ActionController::Server::REUSE_DEFAULT)
    puts "Listening on #{server.print_addresses}"
  end

  # Shutdown message
  puts "#{NAME} motor burns out\n"
end
