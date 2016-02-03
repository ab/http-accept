# Copyright, 2016, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'strscan'

require_relative 'parse_error'
require_relative 'sort'

module HTTP
	module Accept
		class Languages
			LOCALE = /\*|[A-Z]{1,8}(-[A-Z]{1,8})*/i
			
			# https://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.9
			QVALUE = /0(\.[0-9]{0,3})?|1(\.[0]{0,3})?/
			
			LANGUAGE_RANGE = /(?<locale>#{LOCALE})(;q=(?<q>#{QVALUE}))?/
			
			class LanguageRange < Struct.new(:locale, :q)
				def quality_factor
					(q || 1.0).to_f
				end
				
				def self.parse(scanner)
					return to_enum(:parse, scanner) unless block_given?
					
					while scanner.scan(LANGUAGE_RANGE)
						yield self.new(scanner[:locale], scanner[:q])
						
						# Are there more?
						return unless scanner.scan(/\s*,\s*/)
					end
					
					raise ParseError.new("Could not parse entire string!") unless scanner.eos?
				end
				
				# If the user ask for 'en', this satisfies any language that begins with 'en-'
				def prefix_of? other
					other.start_with(locale)
				end
			end
			
			def self.parse(text)
				scanner = StringScanner.new(text)
				
				languages = LanguageRange.parse(scanner)
				
				return Sort.by_quality_factor(languages)
			end
		end
	end
end
