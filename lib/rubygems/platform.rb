require 'rubygems'

# Available list of platforms for targeting Gem installations.
#
class Gem::Platform

  @local = nil

  attr_accessor :cpu

  attr_accessor :os

  attr_accessor :version

  def self.local
    @local ||= new Config::CONFIG['arch']
  end

  def self.match(platform)
    Gem.platforms.any? do |local_platform|
      platform.nil? or local_platform == platform or
        (local_platform != Gem::Platform::RUBY and local_platform =~ platform)
    end
  end

  def initialize(arch)
    case arch
    when Array then
      @cpu, @os, @version = arch
    when String then
      cpu, os = arch.split '-', 2
      cpu, os = nil, cpu if os.nil? # legacy jruby

      @cpu = case cpu
             when /i\d86/ then 'x86'
             else cpu
             end

      @os, @version = case os
                      when /aix(\d+)/ then             [ 'aix',       $1  ]
                      when /cygwin/ then               [ 'cygwin',    nil ]
                      when /darwin(\d+)?/ then         [ 'darwin',    $1  ]
                      when /freebsd(\d+)/ then         [ 'freebsd',   $1  ]
                      when /hpux(\d+)/ then            [ 'hpux',      $1  ]
                      when /^java$/ then               [ 'java',      nil ]
                      when /^java([\d.]*)/ then        [ 'java',      $1  ]
                      when /linux/ then                [ 'linux',     $1  ]
                      when /mingw32/ then              [ 'mingw32',   nil ]
                      when /mswin32(\_(\d+))?/ then
                        if $2 then
                          [ 'mswin32', $2   ]
                        elsif Config::CONFIG['RUBY_SO_NAME'] =~ /^msvcrt-ruby/ then
                          [ 'mswin32', '60' ]
                        else
                          [ 'mswin32', nil  ]
                        end
                      when /netbsdelf/ then            [ 'netbsdelf', nil ]
                      when /openbsd(\d+\.\d+)/ then    [ 'openbsd',   $1  ]
                      when /solaris(\d+\.\d+)/ then    [ 'solaris',   $1  ]
                      # test
                      when /^(\w+_platform)(\d+)/ then [ $1,          $2  ]
                      else                             [ 'unknown',   nil ]
                      end
    else
      raise ArgumentError, "invalid argument #{arch.inspect}"
    end
  end

  def inspect
    "#<%s:0x%x @cpu=%p, @os=%p, @version=%p>" % [self.class, object_id, *to_a]
  end

  def to_a
    [@cpu, @os, @version]
  end

  def to_s
    to_a.compact.join '-'
  end

  def ==(other)
    self.class === other and
      @cpu == other.cpu and @os == other.os and @version == other.version
  end

  def ===(other)
    return nil unless Gem::Platform === other

    # cpu
    (@cpu == 'universal' or other.cpu == 'universal' or @cpu == other.cpu) and

    # os
    @os == other.os and

    # version
    (@version.nil? or other.version.nil? or @version == other.version)
  end

  def =~(other)
    case other
    when Gem::Platform then # nop
    when String then
      # This data is from http://gems.rubyforge.org/gems/yaml on 19 Aug 2007
      other = case other
              when /^i686-darwin(\d)/ then     ['x86',       'darwin',  $1]
              when /^i\d86-linux/ then         ['x86',       'linux',   nil]
              when 'java', 'jruby' then        [nil,         'java',    nil]
              when /mswin32(\_(\d+))?/ then    ['x86',       'mswin32', $2]
              when 'powerpc-darwin' then       ['powerpc',   'darwin',  nil]
              when /powerpc-darwin(\d)/ then   ['powerpc',   'darwin',  $1]
              when /sparc-solaris2.8/ then     ['sparc',     'solaris', '2.8']
              when /universal-darwin(\d)/ then ['universal', 'darwin',  $1]
              else                             other
              end

      other = Gem::Platform.new other
    else
      return nil
    end

    self === other
  end

  ##
  # A pure-ruby gem that may use Gem::Specification#extensions to build
  # binary files.

  RUBY = 'ruby'

  ##
  # A platform-specific gem that is built for the packaging ruby's platform.
  # This will be replaced with Gem::Platform::local.

  CURRENT = 'current'

  ##
  # A One Click Installer-compatible gem

  MSWIN32 = new ['x86', 'mswin32', nil]

  ##
  # An x86 Linux-compatible gem

  X86_LINUX = new ['x86', 'linux', nil]

  ##
  # A PowerPC Darwin-compatible gem

  PPC_DARWIN = new ['ppc', 'darwin', nil]

  # :stopdoc:
  # Here lie legacy constants.  These are deprecated.
  WIN32 = 'mswin32'
  LINUX_586 = 'i586-linux'
  DARWIN = 'powerpc-darwin'
  # :startdoc:

end

