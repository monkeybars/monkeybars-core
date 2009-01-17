# Look in the tasks/setup.rb file for the various options that can be
# configured in this Rakefile. The .rake files in the tasks directory
# are where the options are used.

load 'tasks/setup.rb'

ensure_in_path 'lib'
require 'monkeybars_version'

PROJ.name = 'monkeybars'
PROJ.authors = 'David Koontz, Logan Barnett, Mario Aquino'
PROJ.email = 'david@koontzfamily.org'
PROJ.url = 'http://monkeybars.org'
PROJ.version = Monkeybars::VERSION
PROJ.summary = 
PROJ.rubyforge.name = 'monkeybars'
PROJ.spec.opts << '--color'
PROJ.ruby_opts = []
PROJ.libs << "lib"
PROJ.rdoc.remote_dir = "api"

require 'fileutils'
require 'spec/rake/spectask'

OUTPUT_DIR = "pkg"
BUILD_DIR = "#{OUTPUT_DIR}/bin"
SKELETON_DIR = "skeleton"

task :default => 'spec'

desc "Removes the output directory"
task :clean do
  FileUtils.remove_dir(OUTPUT_DIR) if File.directory? OUTPUT_DIR
  FileUtils.rm("skeleton/lib/java/monkeybars-#{Monkeybars::VERSION}.jar", :force => true)
end

task :update_version_readme do
  readme = IO.readlines( 'README.txt')
  File.open( 'README.txt', 'w' ) { |f| 
    f << "Monkeybars #{Monkeybars::VERSION}\n"
    readme.shift
    f << readme
  }
end

task :prepare do
  Dir.mkdir(OUTPUT_DIR) unless File.directory?(OUTPUT_DIR)
  Dir.mkdir(BUILD_DIR) unless File.directory?(BUILD_DIR)
  Dir.mkdir("skeleton/lib") unless File.directory?("skeleton/lib")
  Dir.mkdir("skeleton/lib/java") unless File.directory?("skeleton/lib/java")
  Dir.mkdir("skeleton/lib/ruby") unless File.directory?("skeleton/lib/ruby")
  File.open( "skeleton/lib/ruby/README.txt" , "w") {|f| f << "3rd party Ruby libs and unpacked gems go here." } unless File.exist?( "skeleton/lib/ruby/README.txt" )
end

task :gem => [:jar]

desc "Creates monkeybars.jar file for distribution"
task :jar => [:prepare, :update_version_readme] do
  Dir.chdir(BUILD_DIR) do
    $stdout << `jar xvf ../../lib/foxtrot.jar`
    FileUtils.remove_dir('META-INF', true)
  end
  $stdout << `jar cf #{OUTPUT_DIR}/monkeybars-#{Monkeybars::VERSION}.jar -C lib monkeybars.rb -C lib monkeybars    -C lib util   -C #{BUILD_DIR} .`
  FileUtils.cp("#{OUTPUT_DIR}/monkeybars-#{Monkeybars::VERSION}.jar", "skeleton/lib/java/monkeybars-#{Monkeybars::VERSION}.jar")
end

desc "Creates a zip file version of the project, excluding files from exclude.lst.  **ONLY WORKS ON OSX/Linux**  Yes this sucks, no I don't want to add another dependency at the moment."
task :zip do
  `zip -vr pkg/monkeybars-#{Monkeybars::VERSION}.zip ../monkeybars -x@exclude.lst`
end

desc "Executes a clean followed by a jar"
task :clean_jar => [:clean, :jar]

#desc "Use this instead of the hoe included install_gem"
#task :mb_install_gem => [:jar, :gem] do
#    $stdout << `gem install -l pkg/monkeybars-#{Monkeybars::VERSION}.gem`
#end

desc "Only used to make RSpec usable with Java Swing code. Wraps up the target of various view tests into a jar that can be require'd and thus loaded on the classpath by JRuby"
task :prepare_spec_jar do
  create_test_jar_file
end

task :spec => [:prepare_spec]

task :prepare_spec do
  create_test_jar_file unless File.exist?("spec/unit/test_files.jar")
end

def create_test_jar_file
  $stdout << `javac spec/unit/org/monkeybars/TestView.java`
  $stdout << `jar -cf spec/unit/test_files.jar -C spec/unit org`
end