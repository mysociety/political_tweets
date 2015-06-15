class AcceptSubmissionJob
  include Sidekiq::Worker

  def perform(submission_id)
    everypolitician = Faraday.new(ENV['EVERYPOLITICIAN_URL'])
    everypolitician.basic_auth(
      ENV['EVERYPOLITICIAN_APP_ID'], ENV['EVERYPOLITICIAN_APP_SECRET']
    )
    everypolitician.post "/accept_submission/#{submission_id}"
  end
end
