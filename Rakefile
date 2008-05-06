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
  t.libs << File.expand_path(File.dirname(__FILE__) + "/lib")
  t.spec_files = FileList['spec/unit/**/*_spec.rb']
  t.spec_opts = ['--color']
end

desc "Removes the output directory"
task :clean do
  FileUtils.remove_dir(OUTPUT_DIR) if File.directory? OUTPUT_DIR
  FileUtils.rm("skeleton/lib/java/monkeybars-#{Monkeybars::VERSION}.jar", :force => true)
end

task :prepare do
  Dir.mkdir(OUTPUT_DIR) unless File.directory?(OUTPUT_DIR)
  Dir.mkdir(BUILD_DIR) unless File.directory?(BUILD_DIR)
  Dir.mkdir("skeleton/lib") unless File.directory?("skeleton/lib")
  Dir.mkdir("skeleton/lib/java") unless File.directory?("skeleton/lib/java")
  Dir.mkdir("skeleton/lib/ruby") unless File.directory?("skeleton/lib/ruby")
  File.open( "skeleton/lib/ruby/README.txt" , "w"){|f| 
     f.puts( "3rd-party Ruby libs go in this dir." ) } unless File.exist?( "skeleton/lib/ruby/README.txt" )
end

desc "Creates monkeybars.jar file for distribution"
task :jar => [:prepare] do
  Dir.chdir(BUILD_DIR) do
    $stdout << `jar xvf ../../lib/foxtrot.jar`
    FileUtils.remove_dir('META-INF', true)
  end
  $stdout << `jar cf #{OUTPUT_DIR}/monkeybars-#{Monkeybars::VERSION}.jar -C lib monkeybars.rb -C lib monkeybars -C #{BUILD_DIR} .`
  FileUtils.cp("#{OUTPUT_DIR}/monkeybars-#{Monkeybars::VERSION}.jar", "skeleton/lib/java/monkeybars-#{Monkeybars::VERSION}.jar")
   
  
end

desc "Creates a zip file version of the project, excluding files from exclude.lst.  **ONLY WORKS ON OSX/Linux**  Yes this sucks, no I don't want to add another dependency at the moment."
task :zip do
  `zip -vr pkg/monkeybars-#{Monkeybars::VERSION}.zip ../monkeybars -x@exclude.lst`
end

desc "Executes a clean followed by a jar"
task :clean_jar => [:clean, :jar]

desc "Use this instead of the hoe included install_gem"
task :mb_install_gem => [:jar, :gem] do
    $stdout << `gem install -l pkg/monkeybars-#{Monkeybars::VERSION}.gem`
end

desc "Only used to make RSpec usable with Java Swing code. Wraps up the target of various view tests into a jar that can be require'd and thus loaded on the classpath by JRuby"
task :prepare_spec_jar do
  $stdout << `javac spec/unit/org/monkeybars/TestView.java`
  $stdout << `jar -cf spec/unit/test_files.jar -C spec/unit org`
end

desc "Builds all the required jars, then makes a shiney new gem."
task :build_all_jars_then_gem => [:prepare_spec_jar , :clean_jar, :gem ]