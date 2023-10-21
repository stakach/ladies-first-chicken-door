# details of the underlying platform
class DoorCtrl::Platform < DoorCtrl::Application
  base "/api/ladiesfirst/platform"

  # Summary of the system
  @[AC::Route::GET("/")]
  def overview
    wifi = wifi_strength rescue -1.0
    {
      cpu_temp:      cpu_temp,
      wifi_strength: wifi,
    }
  end

  # The current CPU temperature
  @[AC::Route::GET("/cpu_temp")]
  def cpu_temp : Float64
    temp_raw = File.read("/sys/class/thermal/thermal_zone0/temp").strip.to_f
    temp_raw / 1000.0
  end

  # The current wifi signal strength
  @[AC::Route::GET("/wifi_strength")]
  def wifi_strength : Float64
    wireless_info = File.read("/proc/net/wireless").strip
    match_data = wireless_info.match(/wlan0:.*\s+(\d+)\./)
    raise "no wifi network found" unless match_data

    # Extract the link quality
    link_quality = match_data[1].to_f

    # Calculate quality as a percentage (assuming a maximum of 70 as in iwconfig)
    max_quality = 70.0
    quality_percentage = (link_quality / max_quality) * 100.0
    quality_percentage.round(1)
  end
end
