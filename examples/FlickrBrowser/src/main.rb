require 'pp'
require 'rbconfig'
require 'java'

$LOAD_PATH << File.dirname(__FILE__)
$LOAD_PATH << File.expand_path( File.join( File.dirname(__FILE__), '..', '..', '..', 'lib') )
$LOAD_PATH << File.expand_path( File.join( File.dirname(__FILE__), 'build', 'classes') )
$CLASSPATH << 'build/classes'
warn "$LOAD_PATH = \n#{$LOAD_PATH.pretty_inspect}"

Dir.glob(File.expand_path(File.dirname(__FILE__) + "/**")).each do |directory|
  $LOAD_PATH << directory unless directory =~ /\.\w+$/ #File.directory? is broken in current JRuby for dirs inside jars
end


require 'manifest'


#===============================================================================
# Platform specific operations, feel free to remove or override any of these
# that don't work for your platform/application

case RbConfig::CONFIG["host_os"]
when /darwin/i
  java.lang.System.setProperty("apple.laf.useScreenMenuBar", "true")
end

# End of platform specific code
#===============================================================================

require 'flickr_browser_controller'

FlickrBrowserController.instance.open
