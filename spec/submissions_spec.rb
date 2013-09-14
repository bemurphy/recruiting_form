feature "Handling form submission flow", js: true, type: :request do

  def extract_approval_path(mail)
    mail.text.match(%r{\shttps?://\S+(/jobs\S+approve)\s})[1]
  end

  scenario "valid data that is then approved" do
    visit "/"

    fill_in "name", with: "John Doe"
    fill_in "email", with: "jdoe@example.com"
    fill_in "company", with: "Foo Bar Inc"
    fill_in "url", with: "http://foobar.example.com"
    fill_in "description", with: "A job for you"

    click_button 'Submit'

    expect(page).to have_content("Thanks, our admins have been notified")

    mail = Malone.deliveries.last
    expect(mail.to).to match(/#{Settings::ADMIN_EMAILS.last}/)
    expect(mail.text).to match(/A job for you/)

    # Approval flow
    approval_path = extract_approval_path(mail)
    visit approval_path
    expect(page).to have_content("Thanks, we've marked that posting approved")

    mail = Malone.deliveries.last
    expect(mail.to).to match(/#{Settings::LIST_ADDRESS}/)
    expect(mail.text).to match(/John Doe/)
    expect(mail.text).not_to match(/jdoe@example.com/)
    expect(mail.text).to match(/Foo Bar Inc/)
    expect(mail.text).to match(/A job for you/)

    # Re-approval notice
    visit approval_path
    expect(page).to have_content("already been approved")
  end

  scenario "with invalid data" do
    visit "/"
    fill_in "description", with: "A bogus post"
    click_button 'Submit'

    expect(page).not_to have_content("Thanks, our admins have been notified")
    mail = Malone.deliveries.last || OpenStruct.new
    expect(mail.text).not_to match(/a bogus post/)
  end

  scenario "a bad authorization for a valid post" do
    visit "/"

    fill_in "name", with: "John Doe"
    fill_in "email", with: "jdoe@example.com"
    fill_in "company", with: "Foo Bar Inc"
    fill_in "url", with: "http://foobar.example.com"
    fill_in "description", with: "A job for you"

    click_button 'Submit'

    mail = Malone.deliveries.last
    approval_path = extract_approval_path(mail)

    approval_path.gsub!(%r{[^/]+/approve}, "bogus/approve")
    visit approval_path
    expect(page).to have_content("Forbidden")
  end

end
