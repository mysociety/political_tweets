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

      def to_everypolitician
        {
          country: site.country_slug,
          legislature: site.legislature_slug,
          person_id: person_id,
          updates: {
            twitter: twitter
          }
        }
      end

      dataset_module do
        def pending
          where(status: 'pending')
        end
      end
    end
  end
end
