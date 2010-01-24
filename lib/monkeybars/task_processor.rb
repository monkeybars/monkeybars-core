include_class "foxtrot.Worker"
include_class "foxtrot.Job"

module Monkeybars
  # Module that contains methods and classes used to take care of background
  # task processing.  Primarily this is the repaint_while method.
  module TaskProcessor
    # Passes the supplied block to a separate thread and returns the result 
    # of the executed block back to the caller.  This should be utilized for long-
    # running tasks that ought not tie up the Swing Event Dispatch Thread.
    # Passing a block to this method will allow the GUI to remain responsive
    # (and repaint), while the long-running task is executing.
    def repaint_while(&task)
      runner = Runner.new(&task)
      Worker.post(runner)
    end
    
    def on_edt(&task)
      if javax.swing.SwingUtilities.event_dispatch_thread?
        javax.swing.SwingUtilities.invoke_later Runnable.new(task)
      else
        javax.swing.SwingUtilities.invoke_and_wait Runnable.new(task)
      end
    end

    module_function :on_edt, :repaint_while

    class Runner < Job
      def initialize(&proc)
        super()
        @proc = proc
      end
    
      def run
        @proc.call
      end
    end
    
    class Runnable
      include Java::java::lang::Runnable
      def initialize(explicit_block=nil, &block)
        @block = explicit_block || block
      end
      
      def run
      	@block.call
      end
    end
  end
end