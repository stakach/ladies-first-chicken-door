require "action-controller/logger"
require "./models/two_factor"

module DoorCtrl
  NAME = "Ladies-First"
  {% begin %}
    VERSION = {{ `shards version "#{__DIR__}"`.chomp.stringify.downcase }}
  {% end %}

  Log         = ::Log.for(NAME)
  LOG_BACKEND = ActionController.default_backend

  ENVIRONMENT   = ENV["SG_ENV"]? || "development"
  IS_PRODUCTION = ENVIRONMENT == "production"

  DEFAULT_PORT          = (ENV["SG_SERVER_PORT"]? || 3000).to_i
  DEFAULT_HOST          = ENV["SG_SERVER_HOST"]? || "127.0.0.1"
  DEFAULT_PROCESS_COUNT = (ENV["SG_PROCESS_COUNT"]? || 1).to_i

  STATIC_FILE_PATH = ENV["PUBLIC_WWW_PATH"]? || "./www"

  IO_CHIP_PATH          = Path[ENV["IO_CHIP_PATH"]? || "/dev/gpiochip0"]
  RELAY_DOOR_OPEN_LINE  = (ENV["RELAY_DOOR_OPEN_LINE"]? || "5").to_i
  RELAY_DOOR_CLOSE_LINE = (ENV["RELAY_DOOR_CLOSE_LINE"]? || "22").to_i

  # security
  TOTP_SECRET           = ENV["TOTP_SECRET"]? || TOTP.generate_base32_secret
  COOKIE_SESSION_KEY    = ENV["COOKIE_SESSION_KEY"]? || "_spider_gazelle_"
  COOKIE_SESSION_SECRET = ENV["COOKIE_SESSION_SECRET"]? || TOTP_SECRET

  def self.running_in_production?
    IS_PRODUCTION
  end

  # flag to indicate if we're outputting trace logs
  class_getter? trace : Bool = false

  # Registers callbacks for USR1 signal
  #
  # **`USR1`**
  # toggles `:trace` for _all_ `Log` instances
  # `namespaces`'s `Log`s to `:info` if `production` is `true`,
  # otherwise it is set to `:debug`.
  # `Log`'s not registered under `namespaces` are toggled to `default`
  #
  # ## Usage
  # - `$ kill -USR1 ${the_application_pid}`
  def self.register_severity_switch_signals : Nil
    # Allow signals to change the log level at run-time
    {% unless flag?(:win32) %}
      Signal::USR1.trap do |signal|
        @@trace = !@@trace
        level = @@trace ? ::Log::Severity::Trace : (running_in_production? ? ::Log::Severity::Info : ::Log::Severity::Debug)
        puts " > Log level changed to #{level}"
        ::Log.builder.bind "#{NAME}.*", level, LOG_BACKEND

        # Ignore standard behaviour of the signal
        signal.ignore

        # we need to re-register our interest in the signal
        register_severity_switch_signals
      end
    {% end %}
  end
end
