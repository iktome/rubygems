# Rakefile for RubyGems      -*- ruby -*-

#--
# Copyright 2006 by Chad Fowler, Rich Kilmer, Jim Weirich and others.
# All rights reserved.
# See LICENSE.txt for permissions.
#++

$:.unshift 'lib'

require 'rubygems'
require 'rake/clean'
require 'rake/testtask'
require 'rubygems/package_task'

def generate_rubygems_version(path, version)
  open path, 'w' do |f|
    f.puts <<-EOF
#--
# DO NOT EDIT
# This file is auto-generated by build scripts.
# See:  rake update_version
#++

module Gem

  ##
  # The version of RubyGems you are using

  RubyGemsVersion = '#{version}'

  ##
  # The version of RubyGems you are using (duplicated for familiarity)

  VERSION = RubyGemsVersion

end
    EOF
  end
end

ENV['CERT_DIR'] ||=  File.join(Gem.user_home, '.gem')

PKG_NAME = 'rubygems'

if ENV['REL'] then
  PKG_VERSION = ENV['REL']
  CURRENT_VERSION = Gem::RubyGemsVersion
else
  PKG_VERSION = Gem::RubyGemsVersion
  CURRENT_VERSION = PKG_VERSION
end

CLOBBER.include(
  '**/debug.log',
  '*.out',
  '.config',
  'data__',
  'html',
  'logs',
  'pkgs/sources/sources*.gem',
  'scripts/*.hieraki',
  'test/data/[a-z]*.gem',
  'test/data/gemhome'
  )
CLOBBER.exclude('test/data/broken-1.0.0.gem')

desc "Run all tests"
task :default => [:test]

desc "Run unit tests (functionals fail on win32)"
task :test => [:test_units]

desc "Run just the unit tests"
Rake::TestTask.new(:test_units) do |t|
  t.test_files = FileList['test/test*.rb']
  t.warning = true
  t.libs = %w[lib test]
end

desc "Run just the functional tests"
Rake::TestTask.new(:test_functional) do |t|
  t.test_files = FileList['test/functional*.rb']
  t.warning = true
end

desc "Run the unit and functional tests"
Rake::TestTask.new(:test_all) do |t|
  t.test_files = FileList['test/{test,functional}*.rb']
  t.warning = true
end

# Shortcuts for test targets
task :tf => [:test_functional]
task :tu => [:test_units]
task :ta => [:test_all]

# --------------------------------------------------------------------
# Creating a release

desc "Make a new release"
task :release => [
  :prerelease,
  :clobber,
  :test_functional,
  :test_units,
  :update_version,
  :package,
  :tag] do

  warn "**************************************************************"
  warn "* Release #{PKG_VERSION} Complete."
  warn "* Packages ready to upload."
  warn "**************************************************************"
end

desc "Validate that everything is ready to go for a release."
task :prerelease do
  warn "**************************************************************"
  warn "* Making RubyGem Release #{PKG_VERSION}"
  warn "* (current version #{CURRENT_VERSION})"
  warn "**************************************************************"

  # Is a release number supplied?
  raise "Usage: rake release REL=x.y.z [REUSE=tag_suffix]" unless ENV['REL']

  # Is the release different than the current release.
  # (or is REUSE set?)
  if PKG_VERSION == CURRENT_VERSION && ! ENV['REUSE']
    raise "Current version is #{PKG_VERSION}, must specify REUSE=tag_suffix to reuse version"
  end

  # Are all source files checked in?
  if ENV['RELTEST'] then
    warn "Release Task Testing, skipping checked-in file test"
  else
    warn "Checking for unchecked-in files..."
    data = `svn st`
    unless data =~ /^$/
      abort "svn status is not clean ... do you have unchecked-in files?"
    end
    warn "No outstanding checkins found ... OK"
  end
end

task :update_version => [:prerelease] do
  if PKG_VERSION == CURRENT_VERSION then
    warn "No version change ... skipping version update"
  else
    warn "Updating RubyGem version to #{PKG_VERSION}"

    generate_rubygems_version 'lib/rubygems/rubygems_version.rb', PKG_VERSION

    if ENV['RELTEST'] then
      warn "Release Task Testing, skipping commiting of new version"
    else
      sh %{svn commit -m "Updated to version #{PKG_VERSION}" lib/rubygems/rubygems_version.rb} # "
    end
  end
end

task :tag => [:prerelease] do
  reltag = "REL_#{PKG_VERSION.gsub(/\./, '_')}"
  reltag = "REL_#{ENV['REUSE'].gsub(/\./, '_')}" if ENV['REUSE']
  warn "Tagging SVN with [#{reltag}]"
  software_dir = File.basename(Dir.pwd)
  if ENV['RELTEST'] then
    warn "Release Task Testing, skipping SVN tagging (in dir #{software_dir})"
  else
    sh %{svn copy svn+ssh://rubyforge.org/var/svn/rubygems/trunk svn+ssh://rubyforge.org/var/svn/rubygems/tags/#{reltag}}
  end
end

begin # rcov
  require 'rcov/rcovtask'

  Rcov::RcovTask.new do |t|
    t.libs << "test"
    t.rcov_opts = ['-xRakefile', '-xrakefile', '-xpublish.rf', '--text-report']
    t.test_files = FileList[
      'test/{functional,test}*.rb'
    ]
    t.verbose = true
  end
rescue LoadError
end

begin # rdoc
  gem 'rdoc'
  require 'rdoc/task'

  desc "Create the RDoc html files"
  RDoc::Task.new :rdoc do |rdoc|
    rdoc.rdoc_dir = 'html'
    rdoc.title    = "RubyGems #{CURRENT_VERSION}"
    rdoc.options << '--line-numbers' << '--main' << 'README'
    rdoc.rdoc_files.include 'README', 'LICENSE.txt', 'GPL.txt', 'lib', 'doc'
  end

  desc "Publish RDoc on RubyForge"
  task :publish_rdoc => ["html/index.html"] do
    sh "rsync -avP --delete html/ rubyforge.org:/var/www/gforge-projects/rubygems/rdoc"
  end
rescue Gem::LoadError
  warn "install RDoc 2.4.2+"
end

# Wiki Doc Targets

desc "Upload the Hieraki Data"
task :upload => [:upload_gemdoc]

task :upload_gemdoc => ['scripts/gemdoc.hieraki'] do
  ruby %{scripts/upload_gemdoc.rb}
end

desc "Build the Hieraki documentation"
task :hieraki => ['scripts/gemdoc.hieraki', 'scripts/specdoc.hieraki']

file 'scripts/gemdoc.hieraki' => ['scripts/gemdoc.rb', 'scripts/gemdoc.data'] do
  chdir('scripts') do
    ruby %{-I../lib gemdoc.rb <gemdoc.data >gemdoc.hieraki}
  end
end

file 'scripts/specdoc.hieraki' =>
  ['scripts/specdoc.rb', 'scripts/specdoc.data', 'scripts/specdoc.yaml'] do
  chdir('scripts') do
    ruby %{-I../lib specdoc.rb >specdoc.hieraki}
  end
end

# Package tasks

PKG_FILES = File.read('Manifest.txt').split "\n"

Rake::PackageTask.new :package do |p|
  p.name          = PKG_NAME
  p.version       = PKG_VERSION
  p.need_tar      = true
  p.need_zip      = true
  p.package_files = PKG_FILES
end

warn_unsigned = true

Spec = Gem::Specification.new do |s|
  s.name                  = PKG_NAME + "-update"
  s.version               = PKG_VERSION
  s.required_ruby_version = Gem::Requirement.new '> 1.8.3'
  s.summary               = "RubyGems update gem"
  s.description           = <<-DESCRIPTION
RubyGems is a package management framework for Ruby.

This gem is an update for the RubyGems software.  You must have an
installation of RubyGems before this update can be applied.
  DESCRIPTION
  s.files                 = PKG_FILES
  s.require_path          = 'lib'
  s.authors               = ['Jim Weirich', 'Chad Fowler', 'Eric Hodel']
  s.email                 = "rubygems-developers@rubyforge.org"
  s.homepage              = "http://rubygems.rubyforge.org"
  s.rubyforge_project     = "rubygems"
  s.bindir                = "bin"
  s.executables           = ["update_rubygems"]

  certdir                 = ENV['CERT_DIR']

  if certdir then
    key  = File.join certdir, 'gem-private_key.pem'
    cert = File.join certdir, 'gem-public_cert.pem'

    warn_unsigned = ! (File.exist? key and File.exist? cert)

    unless warn_unsigned then
      s.signing_key = File.join(certdir, 'gem-private_key.pem')
      s.cert_chain  = [File.join(certdir, 'gem-public_cert.pem')]
    end
  end
end

# Add console output about signing the Gem
file "pkg/#{Spec.full_name}.gem" do
  if warn_unsigned then
    warn "WARNING:  gem will not be signed, no key or certificate found in #{ENV['CERT_DIR']}"
  else
    puts "Signed with certificates in '#{ENV['CERT_DIR']}'"
  end
end

Gem::PackageTask.new Spec do |p| end

desc "Build the Gem spec file for the rubygems-update package"
task :gemspec => "pkg/rubygems-update.gemspec"
file "pkg/rubygems-update.gemspec" => ["pkg", "Rakefile"] do |t|
  open t.name, 'w' do |f|
    f.puts Spec.to_yaml
  end
end

desc "Install RubyGems"
task :install do
  opts = ENV['SETUP_OPTIONS']
  ruby "setup.rb #{opts}".strip

  svnversion = `svnversion`.split(':').last.sub(/[^\d]+/, '').strip

  unless svnversion.empty? then
    File.read('lib/rubygems/rubygems_version.rb') =~ /RubyGemsVersion = '(.*)'/
    current_version = $1.split '.', 4
    rubygems_version = (current_version[0, 3] << svnversion).join '.'
    rubygems_version_file = File.join Gem::ConfigMap[:sitelibdir], 'rubygems',
                                      'rubygems_version.rb'

    generate_rubygems_version rubygems_version_file, rubygems_version
  end
end

# Misc Tasks ---------------------------------------------------------

desc "build util/gem_prelude.rb from the template and defaults.rb"
file 'util/gem_prelude.rb' =>
     %w[util/gem_prelude.rb.template lib/rubygems/defaults.rb] do
  gem_prelude = File.read 'util/gem_prelude.rb.template'
  defaults = File.read 'lib/rubygems/defaults.rb'

  raise 'template error' unless defaults.sub!(/^module Gem\n/, '')
  raise 'template error' unless defaults.sub!(/^end\n/, '')

  defaults.gsub!(/^/, '  ')

  raise 'template error' unless
    gem_prelude.sub!(/^# WARN\n/,
                     "# THIS FILE WAS AUTOGENERATED, DO NOT EDIT\n")
  raise 'template error' unless
    gem_prelude.sub!(/^    # INCLUDE rubygems\/defaults\n/, defaults)

  open 'util/gem_prelude.rb', 'w' do |io|
    io.write gem_prelude
  end
end

# These tasks expect to have the following directory structure:
#
#   git/git.rubini.us/code # Rubinius git HEAD checkout
#   svn/ruby/trunk         # ruby subversion HEAD checkout
#   svn/rubygems/trunk     # RubyGems subversion HEAD checkout
#
# If you don't have this directory structure, set RUBY_PATH and/or
# RUBINIUS_PATH.

diff_options = "-urpN --exclude '*svn*' --exclude '*swp' --exclude '*rbc'"
rsync_options = "-avP --exclude '*svn*' --exclude '*swp' --exclude '*rbc' --exclude '*.rej' --exclude '*.orig' --exclude 'lib/rubygems/defaults/*'"

rubinius_dir = ENV['RUBINIUS_PATH'] || '../../../git/git.rubini.us/code'
ruby_dir = ENV['RUBY_PATH'] || '../../ruby/trunk'

desc "Updates Ruby HEAD with the currently checked-out copy of RubyGems."
task :update_ruby => 'util/gem_prelude.rb' do
  sh "rsync #{rsync_options} bin/gem #{ruby_dir}/bin/gem"
  sh "rsync #{rsync_options} lib/ #{ruby_dir}/lib"
  sh "rsync #{rsync_options} test/ #{ruby_dir}/test/rubygems"
  sh "rsync #{rsync_options} util/gem_prelude.rb #{ruby_dir}/gem_prelude.rb"
end

desc "Diffs Ruby HEAD with the currently checked-out copy of RubyGems."
task :diff_ruby => 'util/gem_prelude.rb' do
  options = "-urpN --exclude '*svn*' --exclude '*swp' --exclude '*rbc'"

  sh "diff #{diff_options} bin/gem #{ruby_dir}/bin/gem; true"
  sh "diff #{diff_options} lib/ubygems.rb #{ruby_dir}/lib/ubygems.rb; true"
  sh "diff #{diff_options} lib/rubygems.rb #{ruby_dir}/lib/rubygems.rb; true"
  sh "diff #{diff_options} lib/rubygems #{ruby_dir}/lib/rubygems; true"
  sh "diff #{diff_options} lib/rbconfig #{ruby_dir}/lib/rbconfig; true"
  sh "diff #{diff_options} test #{ruby_dir}/test/rubygems; true"
  sh "diff #{diff_options} util/gem_prelude.rb #{ruby_dir}/gem_prelude.rb; true"
end

desc "Updates Rubinius HEAD with the currently checked-out copy of RubyGems."
task :update_rubinius => 'util/gem_prelude.rb' do
  sh "rsync #{rsync_options} bin/gem #{rubinius_dir}/lib/bin/gem.rb"
  sh "rsync #{rsync_options} lib/ #{rubinius_dir}/lib"
  sh "rsync #{rsync_options} test/ #{rubinius_dir}/test/rubygems"
  sh "rsync #{rsync_options} util/gem_prelude.rb #{rubinius_dir}/kernel/common/gem_prelude.rb"
end

desc "Diffs Rubinius HEAD with the currently checked-out copy of RubyGems."
task :diff_rubinius => 'util/gem_prelude.rb' do
  sh "diff #{diff_options} bin/gem #{rubinius_dir}/lib/bin/gem.rb; true"
  sh "diff #{diff_options} lib/ubygems.rb #{rubinius_dir}/lib/ubygems.rb; true"
  sh "diff #{diff_options} lib/rubygems.rb #{rubinius_dir}/lib/rubygems.rb; true"
  sh "diff #{diff_options} lib/rubygems #{rubinius_dir}/lib/rubygems; true"
  sh "diff #{diff_options} test #{rubinius_dir}/test/rubygems; true"
  sh "diff #{diff_options} util/gem_prelude.rb #{rubinius_dir}/kernel/common/gem_prelude.rb; true"
end
