require 'pp'

$LOAD_PATH << File.dirname(__FILE__)
$LOAD_PATH << File.expand_path( File.join( File.dirname(__FILE__), '..', '..', '..', 'lib') )
require 'foxtrot.jar'
warn File.dirname(__FILE__)
warn "$LOAD_PATH = \n#{$LOAD_PATH.pretty_inspect}"

Dir.glob(File.expand_path(File.dirname(__FILE__) + "/**")).each do |directory|
  $LOAD_PATH << directory unless directory =~ /\.\w+$/ #File.directory? is broken in current JRuby for dirs inside jars
end


require 'rbconfig'
require 'java'
require 'manifest'


#===============================================================================
# Platform specific operations, feel free to remove or override any of these
# that don't work for your platform/application

case Config::CONFIG["host_os"]
when /darwin/i
  java.lang.System.setProperty("apple.laf.useScreenMenuBar", "true")
end

# End of platform specific code
#===============================================================================

require 'flickr_browser_controller'

FlickrBrowserController.instance.open