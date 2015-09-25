# Background job to send a notification about a new submission
class SendNewSubmissionNotificationJob
  include Sidekiq::Worker

  def perform(submission_id, submission_url)
    submission = Submission[submission_id]
    message = "Hi! You have a new submission for #{submission.site.name}" \
      "on SeePoliticiansTweet which you're an admin for. Please visit " \
      "#{submission_url} to check this submission."
    twitter_user = submission.site.twitter_client.user
    twitter_client.dm(twitter_user.id, message)
  rescue Twitter::Error::Forbidden => e
    puts "Failed to send message to #{twitter_user.name}: #{e.message}"
  end

  def twitter_client
    @twitter_client ||= Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
      config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
      config.access_token        = ENV['TWITTER_ACCESS_TOKEN']
      config.access_token_secret = ENV['TWITTER_ACCESS_SECRET']
    end
  end
end
