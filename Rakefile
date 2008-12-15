require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'rake/contrib/sshpublisher'

spec = Gem::Specification.new do |s|
  s.name              = 'state_machine'
  s.version           = '0.3.1'
  s.platform          = Gem::Platform::RUBY
  s.summary           = 'Adds support for creating state machines for attributes on any Ruby class'
  
  s.files             = FileList['{examples,lib,test}/**/*'] + %w(CHANGELOG.rdoc init.rb LICENSE Rakefile README.rdoc) - FileList['test/app_root/{log,log/*,script,script/*}']
  s.require_path      = 'lib'
  s.has_rdoc          = true
  s.test_files        = Dir['test/**/*_test.rb']
  
  s.author            = 'Aaron Pfeifer'
  s.email             = 'aaron@pluginaweek.org'
  s.homepage          = 'http://www.pluginaweek.org'
  s.rubyforge_project = 'pluginaweek'
end

desc 'Default: run all tests.'
task :default => :test

desc "Test the #{spec.name} plugin."
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.test_files = spec.test_files
  t.verbose = true
end

begin
  require 'rcov/rcovtask'
  namespace :test do
    desc "Test the #{spec.name} plugin with Rcov."
    Rcov::RcovTask.new(:rcov) do |t|
      t.libs << 'lib'
      t.test_files = spec.test_files
      t.rcov_opts << '--exclude="^(?!lib/)"'
      t.verbose = true
    end
  end
rescue LoadError
end

desc "Generate documentation for the #{spec.name} plugin."
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = spec.name
  rdoc.template = '../rdoc_template.rb'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README.rdoc', 'CHANGELOG.rdoc', 'LICENSE', 'lib/**/*.rb')
end
  
Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = true
  p.need_zip = true
end

desc 'Publish the beta gem.'
task :pgem => [:package] do
  Rake::SshFilePublisher.new('aaron@pluginaweek.org', '/home/aaron/gems.pluginaweek.org/public/gems', 'pkg', "#{spec.name}-#{spec.version}.gem").upload
end

desc 'Publish the API documentation.'
task :pdoc => [:rdoc] do
  Rake::SshDirPublisher.new('aaron@pluginaweek.org', "/home/aaron/api.pluginaweek.org/public/#{spec.name}", 'rdoc').upload
end

desc 'Publish the API docs and gem'
task :publish => [:pgem, :pdoc, :release]

desc 'Publish the release files to RubyForge.'
task :release => [:gem, :package] do
  require 'rubyforge'
  
  ruby_forge = RubyForge.new.configure
  ruby_forge.login
  
  %w(gem tgz zip).each do |ext|
    file = "pkg/#{spec.name}-#{spec.version}.#{ext}"
    puts "Releasing #{File.basename(file)}..."
    
    ruby_forge.add_release(spec.rubyforge_project, spec.name, spec.version, file)
  end
end

namespace :state_machine do
  desc 'Draws a set of state machines using GraphViz. Target files to load with FILE=x,y,z; Machine class with CLASS=x,y,z; Font name with FONT=x; Image format with FORMAT=x'
  task :draw do
    # Load the library
    $:.unshift(File.dirname(__FILE__) + '/lib')
    require 'state_machine'
    
    # Build drawing options
    options = {}
    options[:file] = ENV['FILE'] if ENV['FILE']
    options[:path] = ENV['TARGET'] if ENV['TARGET']
    options[:format] = ENV['FORMAT'] if ENV['FORMAT']
    options[:font] = ENV['FONT'] if ENV['FONT']
    
    StateMachine::Machine.draw(ENV['CLASS'], options)
  end
  
  namespace :draw do
    desc 'Draws a set of state machines using GraphViz for a Ruby on Rails application.  Target class with CLASS=x,y,z; Font name with FONT=x; Image format with FORMAT=x'
    task :rails => [:environment, 'state_machine:draw']
    
    desc 'Draws a set of state machines using GraphViz for a Merb application.  Target class with CLASS=x,y,z; Font name with FONT=x; Image format with FORMAT=x'
    task :merb => [:merb_env, 'state_machine:draw']
  end
end
