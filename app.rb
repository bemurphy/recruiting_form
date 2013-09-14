require "sinatra"

require "erubis"
require "json"
require "malone"
require "restclient"
require "scrivener"
require "securerandom"
require "sucker_punch"

set :erb, escape_html: true


module Settings
  # A CouchDB/Cloudant URL for storing the posting in
  DB_URL = ENV.fetch('DB_URL').sub(%r{/\z}, '')

  # The email address to send from
  MAIL_FROM    = ENV.fetch 'MAIL_FROM'

  # The Meetup list email to forward approved postings to
  LIST_ADDRESS = ENV.fetch 'LIST_ADDRESS'

  # URL for the smtp server
  MALONE_URL = ENV.fetch 'MALONE_URL'

  # Host/port (if applicable) for email url use
  HOST = ENV.fetch 'APP_HOST'

  # Recipient emails, comma delimited, of admins to email
  # posting requests to.
  ADMIN_EMAILS = ENV.fetch('ADMIN_EMAILS').split(/\s*,\s*/)
end

# The serialized form data for a job posting
class JobPosting < Scrivener
  attr_accessor :_id, :_rev, :token, :type, :created_at, :approved_at,
    :name, :email, :company, :url, :description

  def initialize(*)
    super
    init_token
    @type = self.class.name
  end

  def id
    _id
  end

  def validate
    assert_present :name
    assert_email :email
    assert_present :company
    assert_url :url
    assert_present :description
    assert_present :token
  end

  def self.[](id)
    raw_doc = RestClient.get("#{Settings::DB_URL}/#{id}")
    new JSON.parse(raw_doc)
  end

  def save
    return false unless valid?

    before_save

    raw_doc = RestClient.post("#{Settings::DB_URL}", attributes.to_json, content_type: 'application/json')
    doc = JSON.parse(raw_doc)

    self._id ||= doc["id"]

    !! doc["ok"]
  end

  def approve
    self.approved_at = Time.now.to_i
  end

  def approve!
    approve && save
  end

  def approved?
    !! approved_at
  end

  private

  def init_token
    @token ||= SecureRandom.urlsafe_base64.gsub(/[^a-z0-9]/i, '')
  end

  def before_save
    self.email = email.downcase
    self.created_at ||= Time.now.to_i
  end
end

# Email notification sent to admins for a new job post request
class AdminNotification
  attr_reader :posting, :recipient

  class Job
    include SuckerPunch::Job

    def perform(posting)
      Settings::ADMIN_EMAILS.each do |email|
        AdminNotification.new(posting, email).deliver
      end
    end
  end

  def initialize(posting, recipient)
    @posting   = posting
    @recipient = recipient
  end

  def auth_path
    "#{posting.id}/#{posting.token}"
  end

  def deliver
    p = posting

    Malone.deliver(from: Settings::MAIL_FROM,
                   to: recipient,
                   subject: "[New Job Posting Request]",
                   text: MESSAGE % [
                     p.name, p.email,
                     p.company, p.url,
                     p.description, auth_path
                   ])
  end

  MESSAGE = <<-EOM
    Greetings,

    %s <%s> has submitted a new job posting request.

    Company: %s

    URL: %s

    Description: %s



    ======================================================

    Please click the following URL to approve this request:

    http://#{Settings::HOST}/jobs/%s/approve

    or you may choose to ignore it.
  EOM
end

# Email sent to meetup once a posting is approved
class MeetupNotification
  attr_reader :posting

  class Job
    include SuckerPunch::Job

    def perform(posting)
      MeetupNotification.new(posting).deliver
    end
  end

  def initialize(posting)
    @posting = posting
  end

  def deliver
    p = posting

    # TODO set a obfuscated reply address
    Malone.deliver(from: "#{p.id}@example.com",
                   to: Settings::LIST_ADDRESS,
                   subject: "[New Job Posting] #{p.company}",
                   text: MESSAGE % [ p.name, p.company, p.url, p.description ])
  end

  MESSAGE = <<-EOM
    %s has submitted a new job posting for OCRuby some of you may be interested in.

    Company: %s

    URL: %s

    Description: %s
  EOM
end

configure do
  Malone.connect(url: Settings::MALONE_URL)
end

###
# Begin Routes

get "/" do
  erb :index
end

post "/jobs" do
  content_type :json

  job_posting = JobPosting.new(params)

  if job_posting.save
    AdminNotification::Job.new.async.perform(job_posting)
    status 202
    {
      status: 'ok',
      msg: 'Thanks, our admins have been notified and will review your request.'
    }.to_json
  else
    status 400
    job_posting.errors.to_json
  end
end

# This is not an idempotent action but, using
# a get to support simple approvals from email
# links.  If this becomes a problem, can just
# make the get render a form for a PUT
get "/jobs/:id/:token/approve" do |id, token|
  @job_posting = JobPosting[id]

  if @job_posting.token != token
    halt 403, "Forbidden"
  end

  if @job_posting.approved?
    @message = "Oh hey, looks like that job posting has already been approved!"
  else
    MeetupNotification::Job.new.async.perform(@job_posting)
    @job_posting.approve!
    @message = "Thanks, we've marked that posting approved and sent it on its way!"
  end

  erb :approval
end
