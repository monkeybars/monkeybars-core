module Monkeybars
  class Resolver
    IN_FILE_SYSTEM = :in_file_system
    IN_JAR_FILE = :in_jar_file
    
    # Returns a const value indicating if the currently executing code is being run from the file system or from within a jar file.
    def self.run_location
      if __FILE__ =~ /\.jar\!/
        :in_jar_file 
      else
        :in_file_system
      end
    end
  end
end

class Object
  def add_to_classpath(path)
    $CLASSPATH << File.expand_path(File.dirname(__FILE__) + "/" + path.gsub("\\", "/"))
  end
end