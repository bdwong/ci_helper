#!/usr/bin/env ruby

# Typical use:
# t = Templator.new
# t.interpolate_files_like("database.yml") # interpolate database.yml.tmpl into database.yml
# t.interpolate_files_like("database.yml", "production") # interpolate database.yml.tmpl.production files into database.yml
# t.with_directory("mydir").interpolate!("database.yml") # search "mydir" and deeper, interpolate "database.yml.tmpl" files
# t.with_options('DATABASE' => 'resultdb')
# No globbing in the source filename or it will mess up the output filename.
# Searches current directory downward by default, or searches from @dir down, templating all files found.
# Accepts options hash, or interpolates from environment.

class Templator
  attr_accessor :options
  attr_accessor :delimiter
  def initialize(opts=nil, delimiter='@@')
    @options = opts || ENV.to_hash
    @delimiter = delimiter
  end
  
  def self.with_options(options)
    new(options)
  end
  
  def self.with_delimiter(delimiter)
    new(nil, delimiter)
  end
  
  def with_delimiter(delimiter)
    @delimiter = delimiter
    self
  end
  
  def with_options(options)
    @options.merge!(options)
    self
  end

  def with_directory(dir)
    @dir = dir
    self
  end
  
  def substitute_template_vars_with_inputs(s)
    vars = s.scan(/#{@delimiter}(\w+)#{@delimiter}/).uniq.flatten
    vars.each{|var| s.gsub!(/#{@delimiter}#{var}#{@delimiter}/, @options[var].nil? ? var : @options[var].to_s)}
  end
  alias_method :interpolate!, :substitute_template_vars_with_inputs
  
  def name_without_extension(n)
    n.gsub(File.extname(n), '')
  end

  def interpolate_files_like(file_patterns, environment="")
    [file_patterns].flatten.each do |file_base_name|
      environment = ".#{environment}" unless environment.nil? || environment == ""
      file_pattern = File.join("**", "#{file_base_name}.tmpl#{environment}")
      file_pattern = File.join(@dir, file_pattern) if @dir
      Dir.glob(file_pattern).each do |tfile|
        puts "configuring #{tfile}"
        template_str = File.read(tfile)
        substitute_template_vars_with_inputs template_str
        new_name = File.join(File.dirname(tfile), file_base_name)
        File.open(new_name, 'w') {|f| f.write(template_str) }
      end
    end
  end

  def ensure_directory(path)
    path.split(File::SEPARATOR).inject('') do |p, e|
      p = File.join(p, e)
        if not File.exist?(p)
          Dir.mkdir(p)
        end
      p
    end
  end
end


if $0 == __FILE__
  t=Templator.new
  t.interpolate_files_like ARGV[0], ARGV[1]
end
