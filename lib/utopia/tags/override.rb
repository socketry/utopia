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

require 'utopia/tags'

class Utopia::Tags::Override
	def self.tag_begin(transaction, state)
		state.overrides[state[:name]] = state[:with]
	end
	
	def self.call(transaction, state)
		transaction.parse_xml(state.content)
	end
end

Utopia::Tags.register("override", Utopia::Tags::Override)
