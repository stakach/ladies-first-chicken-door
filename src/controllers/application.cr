require "base64"
require "uuid"
require "yaml"

abstract class DoorCtrl::Application < ActionController::Base
  # Configure your log source name
  # NOTE:: this is chaining from Log
  Log = DoorCtrl::Log.for("controller")

  # This makes it simple to match client requests with server side logs.
  # When building microservices this ID should be propagated to upstream services.
  @[AC::Route::Filter(:before_action)]
  def set_request_id
    request_id = UUID.random.to_s
    Log.context.set(
      client_ip: client_ip,
      request_id: request_id
    )
    response.headers["X-Request-ID"] = request_id
  end

  # check if authenticated
  @[AC::Route::Filter(:before_action)]
  def ensure_authenticated
    return if session["authed"]?
    if auth = request.headers["Authorization"]?
      auth = Base64.decode_string auth.lchop("Basic ")
      code = auth.split(':', 2)[1]
      if TOTP.validate_number_string(DoorCtrl::TOTP_SECRET, code, 30000)
        session["authed"] = true
        return
      end
    end
    raise AC::Error::Unauthorized.new
  end

  # requests basic authentication
  @[AC::Route::Exception(AC::Error::Unauthorized, status_code: HTTP::Status::UNAUTHORIZED)]
  def unauthorized(_error) : Nil
    response.headers["WWW-Authenticate"] = %(Basic realm="ChickenDoor", charset="UTF-8")
  end

  # covers no acceptable response format and not an acceptable post format
  @[AC::Route::Exception(AC::Route::NotAcceptable, status_code: HTTP::Status::NOT_ACCEPTABLE)]
  @[AC::Route::Exception(AC::Route::UnsupportedMediaType, status_code: HTTP::Status::UNSUPPORTED_MEDIA_TYPE)]
  def bad_media_type(error) : AC::Error::ContentResponse
    AC::Error::ContentResponse.new error: error.message.as(String), accepts: error.accepts
  end

  # handles paramater missing or a bad paramater value / format
  @[AC::Route::Exception(AC::Route::Param::MissingError, status_code: HTTP::Status::UNPROCESSABLE_ENTITY)]
  @[AC::Route::Exception(AC::Route::Param::ValueError, status_code: HTTP::Status::BAD_REQUEST)]
  def invalid_param(error) : AC::Error::ParameterResponse
    AC::Error::ParameterResponse.new error: error.message.as(String), parameter: error.parameter, restriction: error.restriction
  end
end
