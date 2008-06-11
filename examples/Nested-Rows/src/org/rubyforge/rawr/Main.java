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
        System.err.println("Did not find configuration file 'run_configuration', using defaults.");
      }
      else {
        config_yaml = getConfigFileContents(ins);
      }
    }
    catch(IOException ioe)
    {
      System.err.println("Error loading run configuration file 'run_configuration', using defaults: " + ioe);
      config_yaml = "";
    }
    catch(java.lang.NullPointerException npe)
    {
      System.err.println("Error loading run configuration file 'run_configuration', using defaults: " + npe );
      config_yaml = "";
    }

    String bootRuby = "require 'java'\n" + 
      "require 'yaml'\n" + 
      "config_yaml = '" + config_yaml + "'\n" +
      "if config_yaml.strip.empty?\n" +
      "  main_file = 'src/main'\n" +
      "else\n" +
      "  config_hash = YAML.load( \"" + config_yaml + "\" )\n" + 
      "  $LOAD_PATH.unshift(config_hash['ruby_source_dir'])\n" + 
      "  main_file = config_hash['main_ruby_file']\n" + 
      "end\n\n" +
      
      "begin\n" + 
      "  require main_file\n" + 
      "rescue LoadError => e\n" + 
      "  warn 'Error starting the application'\n" + 
      "  warn \"#{e}\\n#{e.backtrace.join(\"\\n\")}\"\n" + 
      "end\n";
    runtime.evalScriptlet(bootRuby);
  }

  public static URL getResource(String path) {
    return Main.class.getClassLoader().getResource(path);
  }

  private static String getConfigFileContents(InputStream input) 
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
