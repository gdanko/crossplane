module CrossPlane
	class Config
		attr_accessor :opts
		attr_accessor :common_opts
		attr_accessor :parse_opts
		attr_accessor :build_opts
		attr_accessor :lex_opts
		attr_accessor :minify_opts
		attr_accessor :format_opts

		def initialize(*args)
			self.common_opts = {

			}

			self.parse_opts = {
				'out' => {:name => :out, :banner => '<string>', :desc => 'write output to a file', :type => :string, :required => false},
				'pretty' => {:name => :pretty, :desc => 'pretty print the json output', :type => :boolean, :required => false},
				'ignore' => {:name => :ignore, :banner => '<str>', :desc => 'ignore directives (comma-separated)', :type => :string, :required => false},
				'no-catch' => {:name => :no_catch, :desc => 'only collect first error in file', :type => :boolean, :required => false},
				'tb-onerror' => {:name => :tb_onerror, :desc => 'include tracebacks in config errors', :type => :boolean, :required => false},
				'combine' => {:name => :combine, :desc => 'use includes to create one single file', :type => :boolean, :required => false},
				'single' => {:name => :single, :desc => 'do not include other config files', :type => :boolean, :required => false},
				'include-comments' => {:name => :include_comments, :desc => 'include comments in json', :type => :boolean, :required => false},
				'strict' => {:name => :strict, :desc => 'raise errors for unknown directives', :type => :boolean, :required => false},
			}

			self.build_opts = {
				'dir' => {:name => :dir, :banner => '<string>', :desc => 'the base directory to build in', :type => :string, :required => false},
				'force' => {:name => :force, :desc => 'overwrite existing files', :type => :boolean, :required => false},
				'indent' => {:name => :indent, :banner => '<string>', :desc => 'number of spaces to indent output', :type => :numeric, :required => false, :default => 4},
				'tabs' => {:name => :tabs, :desc => 'indent with tabs instead of spaces', :type => :boolean, :required => false},
				#'no-headers' => {:name => :no_header2, :desc => 'do not write header to configsd', :type => :boolean, :required => false},
				'stdout' => {:name => :stdout, :desc => 'write configs to stdout instead', :type => :boolean, :required => false},
			}
		end

		def parse_options()
			return self.common_opts.merge(self.parse_opts).map { |_k, v| v }
		end

		def build_options()
			return self.common_opts.merge(self.build_opts).map { |_k, v| v }
		end
	end
end