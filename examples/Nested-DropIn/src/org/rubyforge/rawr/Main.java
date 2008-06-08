package org.rubyforge.rawr;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.InputStream;
import java.io.IOException;
import java.net.URL;


import java.util.ArrayList;
import org.jruby.Ruby;
import org.jruby.javasupport.JavaEmbedUtils;


public class Main
{
  public static void main(String[] args) throws Exception
  {   
    Ruby runtime = JavaEmbedUtils.initialize(new ArrayList(0));
    String config_yaml = "";
    try{
      java.io.InputStream ins = Main.class.getClassLoader().getResourceAsStream("run_configuration");
      if (ins == null ) {
        System.err.println( "InputStream ins is null!");
      }
      else {
        config_yaml = grabConfigFileContents(ins);
      }
    }
    catch(IOException e)
    {
      System.err.println("Error loading run configuration file 'run_configuration', using configuration defaults: " + e);
      config_yaml = "";
    }
    catch(java.lang.NullPointerException ee)
    {
      System.err.println("Error loading run configuration file 'run_configuration', using configuration defaults: " + ee );
      config_yaml = "";
    }

    String bootRuby = "require 'java'\n" + 
      "require 'yaml'\n" + 
      "$: << 'src'\n" + 
      "yaml = '" + config_yaml + "' \n" +
      "begin\n" + 
      "  raise 'No YAML!' if  yaml.strip.empty?\n" + 
      "  config_hash = YAML.load( \"" + config_yaml + "\" )\n" + 
      "  $:.unshift(  config_hash['ruby_source_dir'] )\n" + 
      "  require  config_hash[ 'ruby_source_dir' ] + '/' + config_hash[ 'main_ruby_file' ]\n" + 
      "rescue Exception \n" + 
      "  STDERR.puts \"Error loading config file: \" + $! + \"\nUsing default values.\"\n" + 
      "  begin\n" + 
      "    require 'src/main'\n" + 
      "  rescue LoadError => e\n" + 
      "    warn 'Error starting the application'\n" + 
      "    warn \"#{e}\\n#{e.backtrace.join(\"\\n\")}\"\n" + 
      "  end\n" + 
      "end\n";
    runtime.evalScriptlet( bootRuby );
  }

  public static URL getResource(String path) {
    return Main.class.getClassLoader().getResource(path);
  }

  private static String grabConfigFileContents(InputStream input) 
  throws IOException, java.lang.NullPointerException {

    InputStreamReader isr = new InputStreamReader(input);
    BufferedReader reader = new BufferedReader(isr);
    String line;
    String buf;
    buf = "";
    while ((line = reader.readLine()) != null) {
      buf += line + "\n";
    }
    reader.close();
    return(buf);
  }
}
