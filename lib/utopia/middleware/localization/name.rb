# Copyright (c) 2010 Samuel Williams. Released under the GNU GPLv3.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

module Utopia
	module Middleware
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
end
