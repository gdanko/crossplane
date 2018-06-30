require 'crossplane/errors'
require 'logger'

#require_relative 'errors.rb'

module CrossPlane
	class Utils
		attr_accessor :logger

		def initialize(*args)
			self.logger = configure_logger()
		end

		def isspace(string)
			return string =~ /^\s+$/ ? true : false
		end

		def generate_random(length: 64)
			o = [('a'..'z'), ('A'..'Z')].map(&:to_a).flatten
			string = (0...length).map { o[rand(o.length)] }.join
			string
		end

		def configure_logger(debug: nil)
			logger = Logger.new(STDOUT)
			logger.datetime_format = '%Y-%m-%d %H:%M:%S'
			logger.formatter = proc do |severity, datetime, progname, msg|
				format("[%s] %s\n", severity.capitalize, msg)
			end
			return logger
		end

		def validate_constructor(client: nil, args: nil, required: nil, conflicts: nil, requires: nil, valid: {})
			content = {}
			errors = []
			booleans = ['catch_errors', 'combine', 'comments', 'single', 'strict']
			hashes = []
			arrays = ['ignore']
			ints = ['indent']
			args = Hash[args.map{ |k, v| [k.to_s, v] }]
			args.each do |k, v|
				args.delete(k) if v == nil
			end

			if ((required - args.keys).length != 0)
				errors.push(missing_opts_error(required - args.keys))
			end

			if conflicts.length > 0
				conflicts.each do |conflict_item|
					if (0 && (conflict_item & args.keys).length > 1)
						errors.push(conflicting_opts_error(conflict_item))
					end
				end
			end

			if requires.keys.length > 0
				requires.each do |key, required|
					if args.keys.include?(key)
						intersection = required & args.keys
						unless (required & args.keys).length == required.length
							missing = required - intersection
							if missing.length > 0
								errors.push(missing_requires_error(key, missing))
							end
						end
					end
				end
			end

			if valid['params']
				valid['params'].each do |param|
					if (args.has_key?(param)) and (valid['params'].include?(param))
						if ints.include?(param)
							begin
								content[param.to_sym] = args[param].to_i
							rescue
								errors.push(format('%s must be an integer', param))
							end
						end

						if booleans.include?(param)
							if args[param].is_a?(TrueClass) or args[param].is_a?(FalseClass)
								content[param.to_sym] = args[param] == true ? true : false
							elsif args[param].is_a?(String)
								content[param.to_sym] = args[param].downcase == 'true' ? true : false
							else
								content[param.to_sym] = false
							end
						end
						content[param.to_sym] = args[param]
					end
				end
			end

			if errors.length > 0
				raise CrossPlane::ConstructorError.new(errors: errors)
			else
				return content
			end
		end

		private
		def conflicting_opts_error(conflict)
			return format('the following parameters are mutually exclusive: %s', conflict.join(', '))
		end

		def missing_requires_error(key, missing)
			return format('if you specify "%s", you must also specify: (%s)', key, missing.join(', '))
		end

		def missing_opts_error(missing)
			return format('the following required parameters are missing: %s', missing.join(', '))
		end

		def disallowed_opts_error(disallowed)
			return format('the following disallowed parameters were specified in the constructor: %s', disallowed.join(', '))
		end

		def missing_optional_error(oneof)
			return format('the constructor requires one of the following parameters: %s', oneof.join(', '))
		end

		def too_many_optional_error(oneof)
			return format('the constructor will accept only one of the following parameters: %s', oneof.join(', '))
		end
	end
end