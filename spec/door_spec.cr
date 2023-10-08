require "./spec_helper"

describe DoorCtrl::Door do
  # ==============
  # Test Responses
  # ==============
  client = AC::SpecHelper.client

  it "should provide the current door status" do
    result = client.get("/api/ladiesfirst/door")
    result.body.should eq %({

    })
  end

  it "should change the door state" do
    result = client.post("/api/ladiesfirst/door/close")
    result.body.should eq %({

    })
  end
end
