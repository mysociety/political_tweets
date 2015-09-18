module SeePoliticiansTweet
  module Helpers
    def current_user
      @current_user ||= User[session[:user_id]]
    end

    # Taken from https://developer.github.com/webhooks/securing/
    def verify_signature(payload_body)
      digest = OpenSSL::Digest.new('sha1')
      signature = 'sha1=' + OpenSSL::HMAC.hexdigest(digest, ENV['GITHUB_WEBHOOK_SECRET'], payload_body)
      return halt 500, "Signatures didn't match!" unless Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])
    end

    def everypolitician
      @everypolitician ||= Faraday.new(ENV['EVERYPOLITICIAN_URL'])
    end

    def term_csv(csv)
      'https://raw.githubusercontent.com/' \
        "everypolitician/everypolitician-data/master/#{csv}"
    end
  end
end
