include_class "foxtrot.Worker"
include_class "foxtrot.Job"

module Monkeybars
  module TaskProcessor
    # Passes the supplied block to a separate thread and returns the result 
    # of the executed block back to the caller.  This should be utilized for long-
    # running tasks that ought not tie up the Swing Event Dispatch Thread.
    # IOW, passing a block to this method will allow the GUI to remain responsive
    # (and repaint) while the long-running task is executing.
    def repaint_while(&task)
      runner = Runner.new(&task)
      Worker.post(runner)
    end
    
    class Runner < Job
      def initialize(&proc)
        @proc = proc
      end
    
      def run
        @proc.call
      end
    end
  end
end