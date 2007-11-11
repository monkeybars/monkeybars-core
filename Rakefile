# -*- ruby -*-

require 'rubygems'
require 'fileutils'
require 'hoe'
require 'spec/rake/spectask'

OUTPUT_DIR = "pkg"
BUILD_DIR = "#{OUTPUT_DIR}/bin"
VERSION = "0.5.0"

Hoe.new('monkeybars', VERSION) do |p|
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
  t.spec_files = FileList['spec/unit/**/*.rb']
  t.spec_opts = ['--color']
end

task :clean do
  FileUtils.remove_dir(OUTPUT_DIR) if File.directory? OUTPUT_DIR
end

task :prepare do
  Dir.mkdir(OUTPUT_DIR) unless File.directory?(OUTPUT_DIR)
  Dir.mkdir(BUILD_DIR) unless File.directory?(BUILD_DIR)
  #Dir.mkdir(PACKAGE_DIR) unless File.directory?(PACKAGE_DIR)
end

task :compile => [:prepare] do
  puts 'Compilation of Monkeybars requires that you have some version of the JRuby jar/classes on your classpath.'  
  Dir.glob("lib/**/*.java").each do |file|
    sh "javac -sourcepath lib -d #{BUILD_DIR} #{file}"
  end
end

desc "Creates monkeybars.jar file for distribution"
task :jar => [:compile] do
  sh "jar cf #{OUTPUT_DIR}/monkeybars-#{VERSION}.jar -C lib monkeybars.rb -C lib monkeybars -C #{BUILD_DIR} ."
end

task :clean_jar => [:clean, :jar]

desc "Only used to make RSpec usable with Java Swing code. Wraps up the target of various view tests into a jar that can be require'd and thus loaded on the classpath by JRuby"
task :spec_prepare do
  sh 'javac spec/unit/org/monkeybars/TestView.java'
  sh 'jar -cf spec/unit/test_files.jar -C spec/unit org'
end




# vim: syntax=Ruby
