require 'spec_helper'

describe "Camera management", :type => :feature, :js => true do

  let!(:user) {
    create(:active_user, :password => 'pass')
  }

  it "User adds new camera with correct parameters" do
    cameras_stubs(user)
    page.set_rack_session(:user => user.email)

    visit "/"
    click_link "Add IP Camera"

    fill_in "Friendly Name", :with => 'Test Camera'
    fill_in "Evercam ID", :with => 'testcam'
    fill_in "camera-url", :with => '1.1.1.1'
    fill_in "port", :with => '123'
    fill_in "ext-rtsp-port", :with => '1123'
    fill_in "Snapshot URL", :with => '/snapshot.jpg'
    click_button "Finish & Add"

    # puts "PAGE:\n#{page.public_methods.sort.join("\n")}"
    expect(page).to have_text("Test Camera")
    expect(page).to have_text("testcam")
    expect(page).to have_text("Live View")
  end

  it "User deletes his camera" do
    cameras_stubs(user)
    stub_request(:delete, "#{EVERCAM_API}cameras/testcam.json?api_id=#{user.api_id}&api_key=#{user.api_key}").
      to_return(:status => 200, :body => '{}', :headers => {})

    page.set_rack_session(:user => user.email)

    visit "/"
    first(:link, 'Test Camera').click
    click_link 'camera-settings-link'

    expect(page).to have_text("Settings")
    click_link 'delete-camera-button'
    click_link 'delete-camera-confirm'

    expect(WebMock).to have_requested(:delete, "#{EVERCAM_API}cameras/testcam.json?api_id=#{user.api_id}&api_key=#{user.api_key}").once

    expect(page).to have_text("Camera deleted successfully.")
  end

end