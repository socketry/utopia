
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
