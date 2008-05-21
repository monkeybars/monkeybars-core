#===============================================================================
# Much of the platform specific code should be called before Swing is touched.
# The useScreenMenuBar is an example of this.
require 'rbconfig'
require 'java'

#===============================================================================
# Platform specific operations, feel free to remove or override any of these
# that don't work for your platform/application

case Config::CONFIG["host_os"]
when /darwin/i # OSX specific code
  java.lang.System.set_property("apple.laf.useScreenMenuBar", "true")
when /^win/i # Windows specific code
when /linux/i # Linux specific code
end

# End of platform specific code
#===============================================================================

require 'manifest'

begin
  # Your app logic here, i.e. YourController.instance.open
rescue Exception => e
  $stderr << "Error in application:\n#{e}\n#{e.message}"
  # Additional error handling goes here
  java.lang.System.exit(1)
end