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

module Utopia
	class Localization
		
		module Name
			def self.nonlocalized(resource_name, all_locales)
				resource_name = resource_name.split(".") unless resource_name.kind_of? Array

				# We either have a file extension or an existing locale
				if all_locales.include?(resource_name[-1])
					resource_name.delete_at(-1)
				elsif all_locales.include?(resource_name[-2])
					resource_name.delete_at(-2)
				end

				resource_name
			end

			def self.extract_locale(resource_name, all_locales)
				resource_name = resource_name.split(".") unless resource_name.kind_of? Array

				# We either have a file extension or an existing locale
				if all_locales.include?(resource_name[-1])
					return resource_name[-1]
				elsif all_locales.include?(resource_name[-2])
					return resource_name[-2]
				end
				
				return nil
			end

			def self.localized(resource_name, locale, all_locales)
				nonlocalized_name = nonlocalized(resource_name, all_locales)

				if locale == nil
					return nonlocalized_name
				end

				if nonlocalized_name.size == 1
					return nonlocalized_name.push(locale)
				else
					return nonlocalized_name.insert(-2, locale)
				end
			end
		end
		
	end
end
