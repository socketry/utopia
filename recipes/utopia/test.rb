# frozen_string_literal: true

recipe :coverage do
	ENV['COVERAGE'] = 'PartialSummary'
end

recipe :test do
	system("rspec")
end
