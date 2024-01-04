require "uri"
require "qr-code"
require "qr-code/export/png"
require "crystal-two-factor-auth"

module TwoFactor
  extend self

  def print_totp_qr_code(key_id : String, base32_secret : String)
    url = URI.decode TOTP.otp_auth_url(key_id, base32_secret)
    puts "Writing to 2fa.png: #{url}"

    qr_code = QRCode.new(url).as_png(size: 512)
    File.write("2fa.png", qr_code)
  end
end
