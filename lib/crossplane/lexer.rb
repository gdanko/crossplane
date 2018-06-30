require 'crossplane/errors'
require 'crossplane/globals'

#require_relative 'errors.rb'
#require_relative 'globals.rb'

module CrossPlane
	class Lexer
		EXTERNAL_LEXERS = {}
		NEWLINE = "\n"

		attr_accessor :filename
		def initialize(*args)
			args = args[0] || {}

			required = ['filename']
			conflicts = []
			requires = {}
			valid = {
				'params' => [
					'filename',
				]
			}

			content = CrossPlane.utils.validate_constructor(client: self, args: args, required: required, conflicts: conflicts, requires: requires, valid: valid)
			self.filename = content[:filename]
		end

		def lex(*args)
			tokens = _lex_file()
			_balance_braces(tokens)
			tokens
		end

		private
		def _lex_file(*args)
			token = ''  # the token buffer
			next_token_is_directive = true
			
			enum = Enumerator.new do |y|
				File.open(self.filename, 'r') { |f|
					f.each do |line|
						lineno = $.
						line.split('').each do |char|
							y.yield [char, lineno]
						end
					end
				}
			end

			tokens = []
			begin
				while tuple = enum.next
					char, line = tuple
					if CrossPlane.utils.isspace(char)
						if not token.empty?
							tokens.push([token, line])
							if next_token_is_directive and EXTERNAL_LEXERS[token]
								next_token_is_directive = true
							else
								next_token_is_directive = false
							end
						end

						while CrossPlane.utils.isspace(char)
							char, line = enum.next
						end

						token = ''
					end

					# if starting comment
					if token.empty? and char == '#'
						while not char.end_with?(NEWLINE)
							token = token + char
							char, _ = enum.next
						end
						tokens.push([token, line])
						token = ''
						next
					end

					# handle parameter expansion syntax (ex: "${var[@]}")
					if token and token[-1] == '$' and char == '{'
						next_token_is_directive = false
						while token[-1] != '}' and not CrossPlane.utils.isspace(char)
							token += char
							char, line = enum.next
						end
					end

					# if a quote is found, add the whole string to the token buffer
					if ['"', "'"].include?(char)
						if not token.empty?
							token = token + char
							next
						end
						quote = char
						char, line = enum.next
						while char != quote
							if char == '\\' + quote
								token = token + quote
							else
								token = token + char
							end
							char, line = enum.next
						end

						tokens.push([token, line])
						token = ''
						next
					end

					if ['{', '}', ';'].include?(char)
						if not token.empty?
							tokens.push([token, line])
							token = ''
						end
						tokens.push([char, line]) if char.length > 0
						next_token_is_directive = true
						next
					end
					token = token + char
				end
			rescue StopIteration
			end
			tokens
		end

		def _balance_braces(tokens)
			depth = 0

			for token, line in tokens
				if token == '}'
					depth = depth -1
				elsif token == '{'
					depth = depth + 1
				end

				if depth < 0
					reason = 'unexpected "}"'
					raise CrossPlane::NgxParserSyntaxError.new(self.filename, line, reason)
				else
					yield token, line if block_given?
				end
			end

			if depth > 0
				reason = 'unexpected end of file, expecting "}"'
				raise CrossPlane::NgxParserSyntaxError.new(self.filename, line, reason)
			end
		end
	end
end

