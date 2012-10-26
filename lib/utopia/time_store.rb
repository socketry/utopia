# Copyright, 2012, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'set'
require 'csv'

module Utopia
	
	# TimeStore is a very simple time oriented database. New entries 
	# are added in chronological order and it is not possible to change 
	# this behaviour, or remove old entries. It stores data in a CSV
	# format into a directory where each file represents a week in the 
	# year.
	#
	# The design of this class is to enable efficient logging of data
	# in a backup friendly file format (i.e. files older than one week
	# are not touched).
	#
	# Due to the nature of CSV data, a header must be specified. This
	# header can have columns added, but not removed. Columns not
	# specified in the header will not be recorded.
	#
	class TimeStore
		def initialize(path, header)
			@path = path

			header = header.collect{|name| name.to_s}

			@header_path = File.join(@path, "header.csv")

			if File.exist? @header_path
				@header = File.read(@header_path).split(",")
			else
				@header = []
			end

			diff = (Set.new(header) + ["time"]) - @header

			if diff.size
				@header += diff.to_a.sort

				File.open(@header_path, "w") do |file|
					file.write(@header.join(","))
				end
			end
			
			@last_path = nil
			@last_file = nil
		end

		attr :header

		def path_for_time(time)
			return File.join(@path, time.strftime("%Y-%W") + ".csv")
		end

		def open(time, &block)
			path = path_for_time(time)

			if @last_path != path
				if @last_file
					@last_file.close
					@last_file = nil
				end

				@last_file = File.open(path, "a")
				@last_file.sync = true
				@last_path = path
			end

			yield @last_file

			#File.open(path_for_time(time), "a", &block)
		end

		def dump(values)
			row = @header.collect{|key| values[key.to_sym]}
			return CSV.generate_line(row)
		end

		def <<(values)
			time = values[:time] = Time.now

			open(time) do |file|
				file.puts(dump(values))
			end
		end
	end
	
end