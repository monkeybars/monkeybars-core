# Interface to setting up a handler for any uncaught exceptions in the application.
# The block that is passed into GlobalErrorHandler.on_error will be called when
# an uncaught exception occurs.
# 
# You must be *VERY* careful when implementing your handler.  All uncaught exceptions
# will be routed to this block so any error that occur inside the block will not 
# generate exceptions.
class GlobalErrorHandler
  include Java::java::lang::Thread::UncaughtExceptionHandler
  
  # Creation point for the GlobalErrorHandler.  To use, pass in a block that takes
  # 2 parameters, the exception and the thread that the exception occured on.
  # 
  # The exception passed into this block is a *Java* Throwable, not a Ruby exception.
  # http://java.sun.com/j2se/1.5.0/docs/api/java/lang/Throwable.html
  # 
  #   GlobalErrorHandler.on_error {|exception, thread| puts "Error #{exception} occured on thread #{thread}" }
  # 
  # or you may want to dispatch to an error handler method.
  # 
  #   GlobalErrorHandler.on_error {|exception, thread| my_error_handler_method exception, thread }
  def self.on_error &callback
    java.lang.Thread.default_uncaught_exception_handler = self.new &callback
  end

  def uncaughtException thread, exception
    @callback.call exception, thread
  end
  
private
  def initialize &callback
    @callback = callback
  end
end
