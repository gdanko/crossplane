# crossplane

Reliable and fast NGINX configuration file parser and builder.
This is a Ruby port of the Nginx Python crossplane package which can be found [here](https://github.com/nginxinc/crossplane).

### Install
At this time crossplane is not yet available at [rubygems.org](rubygems.org). However, you can clone the repository and build with `gem build crossplane.gemspec`. You can then install with `gem install crossplane-x.y.z.gem`.

## Command Line Interface
The CLI is still pretty rough. Only a few of the options are currently working.
```
Commands:
  crossplane build           # builds an nginx config from a json payload
  crossplane format          # formats an nginx config file
  crossplane help [COMMAND]  # Describe available commands or one specific command
  crossplane lex             # lexes tokens from an nginx config file
  crossplane minify          # removes all whitespace from an nginx config
  crossplane parse           # parses a json payload for an nginx config
```
#### crossplane parse
This command will take a path to a main NGINX config file as input, then parse the entire config into the schema defined below, and dumps the entire thing as a JSON payload.
```
Usage:
  crossplane parse <filename>

Options:
      [--combine], [--no-combine]                    # use includes to create one single file
      [--ignore=<str>]                               # ignore directives (comma-separated)
      [--include-comments], [--no-include-comments]  # include comments in json
      [--no-catch], [--no-no-catch]                  # only collect first error in file
  -o, [--out=<string>]                               # write output to a file
      [--pretty], [--no-pretty]                      # pretty print the json output
      [--single], [--no-single]                      # do not include other config files
      [--strict], [--no-strict]                      # raise errors for unknown directives
      [--tb-onerror], [--no-tb-onerror]              # include tracebacks in config errors

parses an nginx config file and returns a json payload
```
#### Schema
#### Response Object
```
{
    "status": String, # "ok" or "failed" if "errors" is not empty
    "errors": Array,  # aggregation of "errors" from Config objects
    "config": Array   # Array of Config objects
}
```
#### Config Object
```
{
    "file": String,   # the full path of the config file
    "status": String, # "ok" or "failed" if errors is not empty array
    "errors": Array,  # Array of Error objects
    "parsed": Array   # Array of Directive objects
}
```
#### Directive Object
```
{
    "directive": String, # the name of the directive
    "line": Number,      # integer line number the directive started on
    "args": Array,       # Array of String arguments
    "includes": Array,   # Array of integers (included iff this is an include directive)
    "block": Array       # Array of Directive Objects (included iff this is a block)
}
```
Note
If this is an include directive and the `--single-file` flag was not used, an "includes" value will be used that holds an Array of indices of the configs that are included by this directive.

If this is a block directive, a "block" value will be used that holds an Array of more Directive Objects that define the block context.
#### Error Object
```
{
    "file": String,     # the full path of the config file
    "line": Number,     # integer line number the directive that caused the error
    "error": String,    # the error message
    "callback": Object  # only included iff an "onerror" function was passed to parse()
}
```
Note
If the `--tb-onerror` flag was used by crossplane parse, "callback" will contain a string that represents the traceback that the error caused.
#### Example
Coming soon!
#### crossplane parse (advanced)
This tool uses two flags that can change how crossplane handles errors.

The first, `--no-catch`, can be used if you'd prefer that crossplane quit parsing after the first error it finds.

The second, `--tb-onerror`, will add a "callback" key to all error objects in the JSON output, each containing a string representation of the traceback that would have been raised by the parser if the exception had not been caught. This can be useful for logging purposes.
### crossplane build
This command will take a path to a file as input. The file should contain a JSON representation of an NGINX config that has the structure defined above. Saving and using the output from crossplane parse to rebuild your config files should not cause any differences in content except for the formatting.
```
Usage:
  crossplane build <filename>

Options:
  [--dir=<string>]           # the base directory to build in
  [--force]                  # overwrite existing files
  [--indent=<string>]        # number of spaces to indent output
  [--stdout], [--no-stdout]  # write configs to stdout instead
  [--tabs], [--no-tabs]      # indent with tabs instead of spaces

builds an nginx config from a json payload
```
### crossplane lex
This command takes an NGINX config file, splits it into tokens by removing whitespace and comments, and dumps the list of tokens as a JSON array.
```

Usage:
  crossplane lex

Options:
  -i, [--indent=<int>]                       # number of spaces to indent output
  -n, [--line-numbers], [--no-line-numbers]  # include line numbers in json payload
  -o, [--out=<string>]                       # write output to a file

lexes tokens from an nginx config file
```
#### Example
Passing in this NGINX config file at /etc/nginx/nginx.conf:
```
events {
    worker_connections 1024;
}

http {
    include conf.d/*.conf;
}
```
By running:
```
crossplane lex /etc/nginx/nginx.conf
```
Will result in this JSON output:
```
["events","{","worker_connections","1024",";","}","http","{","include","conf.d/*.conf",";","}"]
```
However, if you decide to use the `--line-numbers flag`, your output will look like:
```
[["events",1],["{",1],["worker_connections",2],["1024",2],[";",2],["}",3],["http",5],["{",5],["include",6],["conf.d/*.conf",6],[";",6],["}",7]]
```
## Ruby Module
In addition to the command line tool, you can require crossplane as a Ruby module. There are two basic functions that the module will provide you: parse and lex.
### crossplane.parse()
```
require 'crossplane/parser'

payload = CrossPlane::Parser.new(
  filename: '/etc/nginx/nginx.conf'
).parse()
```
This will return the same payload as described in the crossplane parse section, except it will be Ruby hashes and not one giant JSON string.
### crossplane.build()
```
require 'crossplane/builder'

config = CrossPlane::Builder.new(
  payload: [{
    "directive": "events",
      "args": [],
      "block": [{
        "directive": "worker_connections",
        "args": ["1024"]
      }]
  }]
).build()
```
This will return a single string that contains an entire NGINX config file.
### crossplane.lex()
```
require 'crossplane/lexer'

tokens = CrossPlane::Lexer.new(
  filename: '/etc/nginx/nginx.conf',
 ).lex()
```
crossplane.lex generates arrays. Inserting these pairs into a list will result in a long list similar to what you can see in the crossplane lex section when the --line-numbers flag is used, except it will obviously be a Ruby array of arrays and not one giant JSON string.
## Contributing
Contributions are welcome, and they are greatly appreciated! Every little bit helps, and credit will always be given.
You can contribute in many ways:
### Types of Contributions
Coming soon!
