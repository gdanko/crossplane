require 'crossplane/analyzer'
require 'crossplane/globals'
require 'crossplane/lexer'
require 'pathname'
require 'pp'

#require_relative 'analyzer.rb'
#require_relative 'globals.rb'
#require_relative 'lexer.rb'

module CrossPlane
	class Parser
		attr_accessor :analyzer
		attr_accessor :ap
		attr_accessor :catch_errors
		attr_accessor :combine
		attr_accessor :comments
		attr_accessor :filename
		attr_accessor :ignore
		attr_accessor :included
		attr_accessor :includes
		attr_accessor :lexer
		attr_accessor :payload
		attr_accessor :single
		attr_accessor :strict

		def initialize(*args)
			args = args[0] || {}

			required = ['filename']
			conflicts = []
			requires = {}
			valid = {
				'params' => [
					'ap',
					'catch_errors',
					'combine',
					'comments',
					'filename',
					'ignore',
					'single',
					'strict',
				]
			}

			content = CrossPlane.utils.validate_constructor(client: self, args: args, required: required, conflicts: conflicts, requires: requires, valid: valid)
			self.ap = (content[:ap] && content[:ap] == true) ? true : false
			self.catch_errors = (content[:catch_errors] && content[:catch_errors] == true) ? true : false
			self.combine = (content[:combine] && content[:combine] == true) ? true : false
			self.comments = (content[:comments] && content[:comments] == true) ? true : false
			self.filename = content[:filename]
			self.ignore = content[:ignore] ? content[:ignore] : []
			self.single = (content[:single] && content[:single] == true) ? true : false
			self.strict = (content[:strict] && content[:strict] == true) ? true : false

			self.analyzer = CrossPlane::Analyzer.new()
			self.lexer = CrossPlane::Lexer.new(filename: self.filename)
		end

		def parse(*args, onerror:nil)
			config_dir = File.dirname(self.filename)

			self.payload = {
				'status' => 'ok',
				'errors' => [],
				'config' => [],
			}

			self.includes = [[self.filename, []]] # stores (filename, config context) tuples
			self.included = {self.filename => 0} # stores {filename: array index} hash

			def _prepare_if_args(stmt)
				args = stmt['args']
				if args and args[0].start_with?('(') and args[-1].end_with?(')')
					args[0] = args[0][1..-1] # left strip this
					args[-1] = args[-1][0..-2].rstrip
					s = args[0].empty? ? 1 : 0
					e = args.length - (args[-1].empty? ? 1 : 0)
					args = args[s..e]
				end
			end

			def _handle_error(parsing, e, onerror: nil)
				file = parsing['file']
				error = e.to_s
				line = e.respond_to?('lineno') ? e.lineno : nil

				parsing_error = {'error' => error, 'line' => line}
				payload_error = {'file' => file, 'error' => error, 'line' => line}
				if not onerror.nil? and not onerror.empty?
					payload_error['callback'] = onerror(e)
				end

				parsing['status'] = 'failed'
				parsing['errors'].push(parsing_error)

				self.payload['status'] = 'failed'
				self.payload['errors'].push(payload_error)
			end

			def _parse(parsing, tokens, ctx:[], consume: false)
				fname = parsing['file']
				parsed = []
			
				begin
					while tuple = tokens.next
						token, lineno = tuple
						# we are parsing a block, so break if it's closing
						break if token == '}'

						if consume == true
							if token == '{'
								_parse(parsing, tokens, consume: true)
							end
						end

						directive = token

						if self.combine
							if self.ap
								stmt = {
									'file' => fname,
									'directive' => directive,
									'args' => [],
								}
							else
								stmt = {
									'file' => fname,
									'directive' => directive,
									'line' => lineno,
									'args' => [],
								}
							end
						else
							if self.ap
								stmt = {
									'directive' => directive,
									'args' => [],
								}
							else
								stmt = {
									'directive' => directive,
									'line' => lineno,
									'args' => [],
								}
							end
						end

						# if token is comment
						if directive.start_with?('#')
							if self.comments
								stmt['directive'] = '#'
								stmt['comment'] = token[1..-1].lstrip
								parsed.push(stmt)
							end
							next
						end

						# TODO: add external parser checking and handling

						# parse arguments by reading tokens
						args = stmt['args']
						token, _ = tokens.next
						while not ['{', '}', ';'].include?(token)
							stmt['args'].push(token)
							token, _ = tokens.next
						end

						if self.ap
							stmt['args'] = [stmt['args'].join(' ')]
						end

						# consume the directive if it is ignored and move on
						if self.ignore.include?(stmt['directive'])
							# if this directive was a block consume it too
							if token == '{'
								_parse(parsing, tokens, consume: true)
							end
							next
						end

						# prepare arguments
						if stmt['directive'] == 'if'
							_prepare_if_args(stmt)
						end

						begin
							# raise errors if this statement is invalid
							self.analyzer.analyze(
								fname,
								stmt,
								token,
								ctx,
								self.strict
							)
						rescue NgxParserDirectiveError => e
							if self.catch_errors
								_handle_error(parsing, e)

								# if it was a block but shouldn't have been then consume
								if e.strerror.end_with(' is not terminated by ";"')
									if token != '}'
										_parse(parsing, tokens, consume: true)
									else
										break
									end
								end
								next
							else
								raise e
							end
						end

						# add "includes" to the payload if this is an include statement
						if not self.single and stmt['directive'] == 'include'
							pattern = args[0]
							p = Pathname.new(args[0])
							if not p.absolute?
								pattern = File.join(config_dir, args[0])
							end

							stmt['includes'] = []

							# get names of all included files
							# ruby needs a python glob.has_magic equivalent
							if pattern =~ /\*/
								fnames = Dir.glob(pattern)
							else
								begin
									open(pattern).close
									fnames = [pattern]
								rescue Exception => e
									f = CrossPlane::NgxParserIncludeError.new(fname, stmt['line'], e.message)
									fnames = []
									if self.catch_errors
										_handle_error(parsing, f)
									else
										raise f
									end
								end
							end

							fnames.each do |fname|
								# the included set keeps files from being parsed twice
								# TODO: handle files included from multiple contexts
								if not self.included.include?(fname)
									self.included[fname] = self.includes.length
									self.includes.push([fname, ctx])
								end
								index = self.included[fname]
								stmt['includes'].push(index)
							end
						end

						# if this statement terminated with '{' then it is a block
						if token == '{'
							inner = self.analyzer.enter_block_ctx(stmt, ctx) # get context for block
							stmt['block'] = _parse(parsing, tokens, ctx: inner)
						end
						parsed.push(stmt)
					end
					return parsed
				rescue StopIteration
					return parsed
				end
			end

			self.includes.each do |fname, ctx|
				tokens = self.lexer.lex().to_enum
				parsing = {
					'file' => fname,
					'status' => 'ok',
					'errors' => [],
					'parsed' => [],
				}

				begin
					parsing['parsed'] = _parse(parsing, tokens.to_enum, ctx: ctx)
				rescue Exception => e
					_handle_error(parsing, e, onerror: onerror)
				end
				self.payload['config'].push(parsing)
			end

			if self.combine
				return _combine_parsed_configs(payload)
			else
				return self.payload
			end
		end
	end
end
