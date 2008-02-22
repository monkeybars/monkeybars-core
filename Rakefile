require 'rubygems'
require 'fileutils'
require 'hoe'
require 'spec/rake/spectask'
require 'lib/monkeybars_version'

OUTPUT_DIR = "pkg"
BUILD_DIR = "#{OUTPUT_DIR}/bin"

Hoe.new('monkeybars', Monkeybars::VERSION) do |p|
  p.rubyforge_name = 'monkeybars'
  p.author = 'David Koontz'
  p.email = 'david@koontzfamily.org'
  p.summary = p.paragraphs_of('README.txt', 1).join("\n\n")
  p.description = p.paragraphs_of('README.txt', 2..-1).join("\n\n")
  p.url = p.paragraphs_of('README.txt', 0).first.split(/\n/)[1..-1]
  p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
end

desc "Run all specs"
Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/unit/**/*_spec.rb']
  t.spec_opts = ['--color']
end

desc "Removes the output directory"
task :clean do
  FileUtils.remove_dir(OUTPUT_DIR) if File.directory? OUTPUT_DIR
  FileUtils.rm("skeleton/lib/monkeybars.jar", :force => true)
end

task :prepare do
  Dir.mkdir(OUTPUT_DIR) unless File.directory?(OUTPUT_DIR)
  Dir.mkdir(BUILD_DIR) unless File.directory?(BUILD_DIR)
  Dir.mkdir("skeleton/lib") unless File.directory?("skeleton/lib")
end

desc "Creates monkeybars.jar file for distribution"
task :jar => [:prepare] do
  puts `jar cf #{OUTPUT_DIR}/monkeybars-#{Monkeybars::VERSION}.jar -C lib monkeybars.rb -C lib monkeybars -C #{BUILD_DIR} .`
  FileUtils.cp("#{OUTPUT_DIR}/monkeybars-#{Monkeybars::VERSION}.jar", "skeleton/lib/monkeybars.jar")
end

desc "Executes a clean followed by a jar"
task :clean_jar => [:clean, :jar]

desc "Use this instead of the hoe included install_gem"
task :mb_install_gem => [:jar, :gem] do
    puts `gem install pkg/monkeybars-#{Monkeybars::VERSION}.gem`
end

desc "Only used to make RSpec usable with Java Swing code. Wraps up the target of various view tests into a jar that can be require'd and thus loaded on the classpath by JRuby"
task :spec_prepare do
  puts `javac spec/unit/org/monkeybars/TestView.java`
  puts `jar -cf spec/unit/test_files.jar -C spec/unit org`
end