#===============================================================================
# Much of the platform specific code should be called before Swing is touched.
# The useScreenMenuBar is an example of this.
require 'rbconfig'
require 'java'
require 'rubygems'

#===============================================================================
# Platform specific operations, feel free to remove or override any of these
# that don't work for your platform/application

case RbConfig::CONFIG["host_os"]
when /darwin/i # OSX specific code
  java.lang.System.set_property("apple.laf.useScreenMenuBar", "true")
when /^win|mswin/i # Windows specific code
when /linux/i # Linux specific code
end

# End of platform specific code
#===============================================================================
$LOAD_PATH.clear
$LOAD_PATH << File.expand_path(File.dirname(__FILE__))

require 'manifest'

# Set up global error handling so that it is consistantly logged or outputed
# You will probably want to replace the puts with your application's logger
def show_error_dialog_and_exit(exception, thread=nil)
  puts "Error in application"
  puts "#{exception.class} - #{exception}"
  if exception.kind_of? Exception
    puts exception.backtrace.join("\n")
  else
    # Workaround for JRuby issue #2673, getStackTrace returning an empty array
    output_stream = java.io.ByteArrayOutputStream.new
    exception.printStackTrace(java.io.PrintStream.new(output_stream))
    puts output_stream.to_string
  end

  # Your error handling code goes here
  
  # Show error dialog informing the user that there was an error
  title = "Application Error"
  message = "The application has encountered an error and must shut down."
  
  javax.swing.JOptionPane.show_message_dialog(nil, message, title, javax.swing.JOptionPane::DEFAULT_OPTION)
  java.lang.System.exit(0)
end
GlobalErrorHandler.on_error {|exception, thread| show_error_dialog_and_exit(exception, thread)}

begin
  # Your application code goes here
  require 'diff_controller'
  DiffController.create_instance.open
rescue => e
  show_error_dialog_and_exit(e)
end
