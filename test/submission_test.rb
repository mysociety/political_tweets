require 'test_helper'

describe Submission do
  describe '#status' do
    let(:user) { User.create(twitter_uid: '123', token: '321', secret: 'shh') }
    let(:site) { user.add_site(name: 'Test Site', country_slug: 'Test', legislature_slug: 'Site', latest_term_csv: 'test.csv') }
    subject { site.add_submission(twitter: 'foobar', person_id: '42', site_id: site.id) }
    it 'defaults to pending' do
      assert_equal 'pending', subject.status
      assert_raises(Sequel::ValidationFailed) { subject.update(status: 'invalid') }
      subject.update(status: 'approved')
      assert_equal 'approved', subject.status
    end
  end
end
