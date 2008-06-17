require 'java'

# Load subdirectories in src onto the load path
Dir.glob(File.expand_path(File.dirname(__FILE__) + "/**")).each do |directory|
  $LOAD_PATH << directory unless directory =~ /\.\w+$/ #File.directory? is broken in current JRuby for dirs inside jars
end

#===============================================================================
# Monkeybars requires, this pulls in the requisite libraries needed for
# Monkeybars to operate.


class File
  class_eval do
    class << self
      alias_method :new_expand_path, :expand_path
    end
  end

  def File.is_jnlp_url?(path)
    path =~ /^http/i
  end

  def File.expand_path fname, dir_string=nil
    if is_jnlp_url?(fname)
      _ = fname.split( 'jar!/').last
       "./#{_}"
    else
      new_expand_path( fname, dir_string )
    end
  end
end

require 'resolver'

case Monkeybars::Resolver.run_location
when Monkeybars::Resolver::IN_FILE_SYSTEM
  add_to_classpath "../lib/java/monkeybars-0.6.2.jar"
end

require 'monkeybars'
require 'application_controller'
require 'application_view'

# End of Monkeybars requires
#===============================================================================
#
# Add your own application-wide libraries below.  To include jars, append to
# $CLASSPATH, or use add_to_classpath, for example:
# 
# $CLASSPATH << File.expand_path(File.dirname(__FILE__) + "/../lib/swing-layout-1.0.3.jar")
#
# or
#
# add_to_classpath "../lib/swing-layout-1.0.3.jar"

require 'rubygems'

case Monkeybars::Resolver.run_location
when Monkeybars::Resolver::IN_FILE_SYSTEM
  add_to_classpath "../lib/java/jruby-complete.jar"
  add_to_classpath "../lib/java/swing-layout-1.0.3.jar"
  add_to_classpath "../lib/java/monkeybars-0.6.2.jar"
  add_to_classpath "../build/classes"
  $LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../lib/java")
when Monkeybars::Resolver::IN_JAR_FILE
  $LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../../lib/java").gsub("file:", "")
end

$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../lib/ruby")