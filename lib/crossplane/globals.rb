require 'crossplane/config'
require 'crossplane/utils'

#require_relative 'config.rb'
#require_relative 'utils.rb'

module CrossPlane
	def self.utils=(utils)
		@utils = utils
	end

	def self.utils
		@utils
	end
	
	def self.config=(config)
		@config = config
	end

	def self.config
		@config
	end

	def self.debug=(debug)
		@debug = debug
	end

	def self.debug
		@debug
	end

	def self.logger=(logger)
		@logger = logger
	end

	def self.logger
		@logger || CrossPlane.utils.configure_logger(debug: true)
	end

	CrossPlane.config = CrossPlane::Config.new()
	CrossPlane.utils = CrossPlane::Utils.new()
end