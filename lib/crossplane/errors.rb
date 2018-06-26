module CrossPlane
	class ConstructorError < StandardError
		def initialize(errors: nil)
			@errors = errors
			@error = @errors.join('; ')
			super(@error)
		end
	end

	class NgxParserBaseException < StandardError
		attr_reader :filename, :lineno, :strerror
		def initialize(filename, lineno, strerror)
			@filename = filename
			@lineno = lineno
			@strerror = strerror
			if @lineno.nil?
				@error = format('%s in %s', @strerror, @filename)
			else
				@error = format('%s in %s:%s', @strerror, @filename, @lineno)
			end
			super(@error)
		end
	end

	class NgxParserDirectiveError < StandardError
		def initialize(reason, filename, lineno)
			@reason = reason
			@filename = filename
			@lineno = lineno
			@error = (format('%s in %s:%s', @reason, @filename, @lineno))
			super(@error)
		end
	end

	class NgxParserSyntaxError < NgxParserBaseException
		def initialize(filename, lineno, strerror)
			super(filename, lineno, strerror)
		end
	end

	class NgxParserDirectiveArgumentsError < NgxParserBaseException
		def initialize(filename, lineno, strerror)
			super(filename, lineno, strerror)
		end
	end

	class NgxParserDirectiveContextError < NgxParserBaseException
		def initialize(filename, lineno, strerror)
			super(filename, lineno, strerror)
		end
	end

	class NgxParserDirectiveUnknownError < NgxParserBaseException
		def initialize(filename, lineno, strerror)
			super(filename, lineno, strerror)
		end
	end

	class NgxParserIncludeError < NgxParserBaseException
		def initialize(filename, lineno, strerror)
			super(filename, lineno, strerror)
		end
	end
end