
class NilClass
	def maybe?
	end
end

class Object
	# A helper that allows you to avoid excessive number of i
	def maybe?
		yield self
	end
end
