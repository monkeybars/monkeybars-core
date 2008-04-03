$LOAD_PATH << File.dirname(__FILE__)
Dir.glob(File.expand_path(File.dirname(__FILE__) + "/**")).each do |directory|
  $LOAD_PATH << directory unless directory =~ /\.\w+$/ #File.directory? is broken in current JRuby for dirs inside jars
end

require 'manifest'
require 'rbconfig'

#===============================================================================
# Platform specific operations, feel free to remove or override any of these
# that don't work for your platform/application

case Config::CONFIG["host_os"]
when /darwin/i # OSX specific code
  java.lang.System.setProperty("apple.laf.useScreenMenuBar", "true")
when /win/i # Windows specific code
when /linux/i # Linux specific code
end

# End of platform specific code
#===============================================================================

