module DoorCtrl
  enum DoorState
    Open
    Close
    Sensor
    Invalid
  end

  struct State
    include JSON::Serializable

    getter state : DoorState
    getter close_line : Int32
    getter? close_active : Bool
    getter open_line : Int32
    getter? open_active : Bool

    def initialize(close_line : GPIO::Line, open_line : GPIO::Line)
      @close_line = close_line.offset
      @open_line = open_line.offset
      @close_active = close_line.high?
      @open_active = open_line.high?

      @state = if @close_active && @open_active
                 DoorState::Invalid
               elsif !@close_active && !@open_active
                 DoorState::Sensor
               elsif @close_active
                 DoorState::Close
               else
                 DoorState::Open
               end
    end
  end
end
