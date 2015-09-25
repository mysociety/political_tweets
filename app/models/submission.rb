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

      dataset_module do
        def pending
          where(status: 'pending')
        end
      end
    end
  end
end
