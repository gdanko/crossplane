#require 'crossplane/globals'
require 'json'
require 'pathname'
require 'pp'

require_relative 'globals.rb'

module CrossPlane
	class Builder
		DELIMITERS = ['{', '}', ';']
		EXTERNAL_BUILDERS = {}
		NEWLINE = "\n"
		TAB = "\t"

		attr_accessor :ap
		attr_accessor :header
		attr_accessor :indent
		attr_accessor :padding
		attr_accessor :payload
		attr_accessor :state
		attr_accessor :tabs

		def initialize(*args)
			args = args[0] || {}

			required = ['payload']
			conflicts = []
			requires = {}
			valid = {
				'params' => [
					'ap',
					'header',
					'indent',
					'payload',
					'tabs',
				]
			}

			content = CrossPlane.utils.validate_constructor(client: self, args: args, required: required, conflicts: conflicts, requires: requires, valid: valid)
			self.ap = (content[:ap] && content[:ap] == true) ? true : false
			self.header = (content[:header] && content[:header] == true) ? true : false
			self.indent = content[:indent] ? content[:indent] : 4
			self.payload = content[:payload] ? content[:payload] : nil
			self.tabs = (content[:tabs] && content[:tabs] == true) ? true : false
		end

		def build(*args)
			self.padding = self.tabs ? TAB : ' ' * self.indent
			self.state = {
				'prev_obj' => nil,
				'depth' => -1,
			}

			if self.header
				lines = [
					"# This config was built from JSON using NGINX crossplane.\n",
					"# If you encounter any bugs please report them here:\n",
					"# https://github.com/nginxinc/crossplane/issues\n",
					"\n"
				]
			else
				lines = []
			end

			lines += _build_lines(payload)
			puts lines.join('')
			exit
			return lines.join('')
		end

		private
		def _put_line(line, obj)
			margin = self.padding * self.state['depth']

			# don't need put \n on first line and after comment
			if self.state['prev_obj'].nil?
				return margin + line
			end

			# trailing comments have to be without \n
			if obj['directive'] == '#' and obj['line'] == self.state['prev_obj']['line']
				return ' ' + line
			end

			return NEWLINE + margin + line
		end

		def _build_lines(objs)
			lines = Enumerator.new do |y|
				self.state['depth'] = self.state['depth'] + 1

				objs.each do |obj|
					directive = obj['directive']
					if EXTERNAL_BUILDERS[directive]
						#built = external_builder(obj, padding, state)
						#y.yield(_put_line(built_obj))
						#next
					end

					if directive == '#'
						y.yield(_put_line(
							'#' + obj['comment'],
							obj
						))
						next
					end

					args = obj['args'].map{|arg| _enquote(arg)}

					if directive == 'if'
						line = format('if (%s)', args.join(' '))
					elsif args
						line = format('%s %s', directive, args.join(' '))
					else
						line = directive
					end

					if not obj.key?('block')
						y.yield(_put_line(line + ';', obj))
					else
						y.yield(_put_line(line + ' {', obj))

						# set prev_obj to propper indentation in block
						self.state['prev_obj'] = obj
						_build_lines(obj['block']).each do |line|
							y.yield(line)
						end
						y.yield(_put_line('}', obj))
					end
					self.state['prev_obj'] = obj
				end
				self.state['depth'] = self.state['depth'] - 1
			end
			lines.to_a
		end

		def _escape(string)
			chars = Enumerator.new do |y|
				prev, char = '', ''
				string.split('').each do |char|
					if prev == '\\' or prev + char == '${'
						prev += char
						y.yield char
						next
					end
					
					if prev == '$'
						y.yield prev
					end

					if not ['\\', '$'].include?(char)
						y.yield char
					end
					prev = char
				end

				if ['\\', '$'].include?(char)
					y.yield char
				end
			end
			chars
		end

		def _needs_quotes(string)
			if string == ''
				return true
			elsif DELIMITERS.include?(string)
				return false
			end

			# lexer should throw an error when variable expansion syntax
			# is messed up, but just wrap it in quotes for now I guess
			chars = _escape(string)

			begin
				while char = chars.next


					# arguments can't start with variable expansion syntax
					if CrossPlane.utils.isspace(char) or ['{', ';', '"', "'", '${'].include?(char)
						return true
					end

					expanding = false
					#chars.each do |char|
					#	if CrossPlane.utils.isspace(char) or ['{', ';', '"', "'"].include(char)
					#		return true
					#	elsif char == 
					# char in ('\\', '$') or expanding
					return expanding
				end
			rescue StopIteration
			end
		end

		def _enquote(arg)
			if _needs_quotes(arg)
				#arg = repr(codecs.decode(arg, 'raw_unicode_escape'))
				arg = arg.gsub('\\\\', '\\')
			end
			return arg
		end


	end
end