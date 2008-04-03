#===============================================================================
# Monkeybars requires, this pulls in the requisite libraries needed for
# Monkeybars to operate.

require 'java'
require 'resolver'

case Monkeybars::Resolver.run_location
when Monkeybars::Resolver::IN_FILE_SYSTEM
  $CLASSPATH << File.expand_path(File.dirname(__FILE__) + '/../lib/monkeybars-0.6.1.jar')
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
# is equivalent to
#
# add_to_classpath "../lib/swing-layout-1.0.3.jar"

case Monkeybars::Resolver.run_location
when Monkeybars::Resolver::IN_FILE_SYSTEM
  # Files to be added only when running from the file system go here
when Monkeybars::Resolver::IN_JAR_FILE
  # Files to be added only when run from inside a jar file
end