#===============================================================================
# Monkeybars requires, this pulls in the requisite libraries needed for
# Monkeybars to operate.

$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/../lib"))

require 'java'
require 'monkeybars.jar'
require 'monkeybars'

# End of Monkeybars requires
#===============================================================================
#
# Add your own application-wide libraries below.  To include jars, append to
# $CLASSPATH, for example:
# 
# $CLASSPATH << 'swing-layout-1.0.3.jar'

