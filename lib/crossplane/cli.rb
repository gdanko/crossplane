require 'crossplane/builder'
require 'crossplane/config'
require 'crossplane/parser'
require 'json'
require 'logger'
require 'pp'
require 'thor'
require 'yaml'

#require_relative 'builder.rb'
#require_relative 'config.rb'
#require_relative 'parser.rb'

$script = File.basename($0)
$config = CrossPlane::Config.new()

trap('SIGINT') {
	puts("\nControl-C received.")
	exit(0)
}

def configure_options(thor, opt_type, opts)
	opts = opts.sort_by { |k| k[:name].to_s }
	opts.each do |opt|
		required = opt.key?(:required) ? opt[:required] : false
		aliases = opt.key?(:aliases) ? opt[:aliases] : []
		if opt_type == "class"
			thor.class_option(opt[:name], :banner => opt[:banner], :desc => opt[:desc], :aliases => aliases, :required => required, :type => opt[:type])
		elsif opt_type == "method"
			thor.method_option(opt[:name], :banner => opt[:banner], :desc => opt[:desc], :aliases => aliases, :required => required, :type => opt[:type])
		end
	end
end

class CLI < Thor
	desc 'parse <filename>', 'parses an nginx config file and returns a json payload'
	configure_options(self, 'method', $config.parse_options)
	def parse(filename)
		payload = CrossPlane::Parser.new(
			filename: filename,
			combine: options['combine'] || false,
			strict: options['strict'] || false,
			catch_errors: options['no_catch'] ? false : true,
			comments: options['include_comments'] || false,
			ignore: options['ignore'] ? options['ignore'].split(/\s*,\s*/) : [],
			single: options['single'] || false,
		).parse()
		
		if options['out']
			File.open(options['out'], 'w') do |f|
				f.write(JSON.pretty_generate(payload))
			end
		else
			puts options['pretty'] ? JSON.pretty_generate(payload) : payload.to_json
		end
		exit 0
	end

	desc 'build <filename>', 'builds an nginx config from a json payload'
	configure_options(self, 'method', $config.build_options)
	def build(filename)
		dirname = Dir.pwd unless dirname
		
		# read the json payload from the specified file
		payload = JSON.parse(File.read(filename))
		builder = CrossPlane::Builder.new(
			payload: payload['config'][0]['parsed']
		)	
		
		if not options['force'] and not options['stdout']
			existing = []
			payload['config'].each do |config|
				path = config['file']
				p = Pathname.new(path)
				path = p.absolute? ? path: File.join(dirname, path)
				if File.exist?(path)
					existing.push(path)
				end
			end


			# ask the user if it's okay to overwrite existing files
			if existing.length > 0
				puts(format('building %s would overwrite these files:', filename))
				puts existing.join("\n")
				# if not _prompt_yes():
				#   print('not overwritten')
				#   return
			end
		end

		# if stdout is set then just print each file after another like nginx -T
		#if options['stdout']
			payload['config'].each do |config|
				path = config['file']
				p = Pathname.new(path)
				path = p.absolute? ? path: File.join(dirname, path)
				parsed = config['parsed']
				output = builder.build(
					parsed,
					indent: options['indent'] || 4, # fix default option in config.rb
					tabs: options['tabs'],
					header: options['header']
				)
				output = output.rstrip + "\n"
				puts output
			end
			#puts output
		#end
	end

	desc 'lex <filename>', 'lexes tokens from an nginx config file'
	configure_options(self, 'method', $config.lex_options)
	def lex(filename)
		payload = CrossPlane::Lexer.new(
			filename: filename,
		).lex()
		lex = (not options['line_numbers'].nil? and options['line_numbers'] == true) ? payload : payload.map{|e| e[0]}

		if options['out']
			File.open(options['out'], 'w') do |f|
				f.write(JSON.pretty_generate(lex))
			end
		else
			puts options['pretty'] ? JSON.pretty_generate(lex) : lex.to_json
		end
	end

	desc 'minify', 'removes all whitespace from an nginx config'
	def minify(filename)
		puts 'minifiy'
		exit
	end

	#desc 'format', 'formats an nginx config file'
	#def format(filename)
	#	puts 'format'
	#	exit
	#end
end
