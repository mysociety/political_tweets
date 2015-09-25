module SeePoliticiansTweet
  module Models
    class Submission < Sequel::Model
      many_to_one :site

      def before_validation
        self.status ||= 'pending'
        super
      end

      def validate
        super
        validates_includes ['pending', 'approved', 'rejected'], :status
      end
    end
  end
end
