require "gpio"

# door control API
class DoorCtrl::Door < DoorCtrl::Application
  base "/api/ladiesfirst/door"

  class_getter io_chip : GPIO::Chip do
    GPIO.default_consumer = "ladies first chicken door"
    GPIO::Chip.new(IO_CHIP_PATH)
  end

  class_getter open_relay : GPIO::Line do
    line = io_chip.line(RELAY_DOOR_OPEN_LINE)
    line.request_output
    line
  end

  class_getter close_relay : GPIO::Line do
    line = io_chip.line(RELAY_DOOR_CLOSE_LINE)
    line.request_output
    line
  end

  @@mutex = Mutex.new

  getter close_relay : GPIO::Line { self.class.close_relay }
  getter open_relay : GPIO::Line { self.class.open_relay }

  # the current state of the chicken door
  @[AC::Route::GET("/")]
  def status : State
    State.new(close_relay, open_relay)
  end

  # change the state of the chicken door
  @[AC::Route::POST("/:door")]
  def set_state(door : DoorState) : State
    @@mutex.synchronize do
      door_current = status
      case door
      in .open?
        unless door_current.state.open?
          close_relay.set_low
          open_relay.set_high
        end
      in .close?
        unless door_current.state.close?
          open_relay.set_low
          close_relay.set_high
        end
      in .sensor?
        unless door_current.state.sensor?
          open_relay.set_low
          close_relay.set_low
        end
      in .invalid?
        raise AC::Route::Param::ValueError.new("bad door state value", "door", "one of open, close or sensor")
      end
      status
    end
  end
end
