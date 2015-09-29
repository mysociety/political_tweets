class AcceptSubmissionJob
  include Sidekiq::Worker

  def perform(submission_id)
    submission = Submission[submission_id]
    everypolitician = Faraday.new(ENV['EVERYPOLITICIAN_URL'])
    everypolitician.post '/submissions', submission.to_everypolitician
  end
end
