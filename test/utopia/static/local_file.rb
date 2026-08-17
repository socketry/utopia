# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "tmpdir"

require "utopia/static/local_file"

describe Utopia::Static::LocalFile do
	it "uses a consistent metadata snapshot" do
		Dir.mktmpdir do |directory|
			path = File.join(directory, "test.txt")
			File.write(path, "Original")
			
			file = subject.new(path)
			mtime_date = file.mtime_date
			etag = file.etag
			
			File.write(path, "Updated content")
			
			expect(file.bytesize).to be == 8
			expect(file.mtime_date).to be == mtime_date
			expect(file.etag).to be == etag
		end
	end
	
	it "includes subsecond modification time in entity tags" do
		Dir.mktmpdir do |directory|
			path = File.join(directory, "test.txt")
			File.write(path, "Content")
			
			seconds = Time.now.to_i - 1
			first_mtime = Time.at(seconds, 100_000_000, :nanosecond)
			second_mtime = Time.at(seconds, 200_000_000, :nanosecond)
			
			File.utime(first_mtime, first_mtime, path)
			first = subject.new(path)
			
			File.utime(second_mtime, second_mtime, path)
			second = subject.new(path)
			
			expect(first.mtime_date).to be == second.mtime_date
			expect(first.etag).not.to be == second.etag
		end
	end
	
	it "matches strong entity tags for range requests" do
		Dir.mktmpdir do |directory|
			path = File.join(directory, "test.txt")
			File.write(path, "Content")
			
			file = subject.new(path)
			file.instance_variable_set(:@etag, '"strong"')
			
			expect(file.send(:if_range?, '"strong"')).to be == true
			expect(file.send(:if_range?, '"different"')).to be == false
		end
	end
end
