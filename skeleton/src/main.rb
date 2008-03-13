require 'manifest'
require 'rbconfig'

#===============================================================================
# Platform specific operations, feel free to remove or override any of these
# that don't work for your platform/application

case Config::CONFIG["host_os"]
when /darwin/i
  apple.laf.use_screen_menu_bar="true"
end

# End of platoform specific code
#===============================================================================

