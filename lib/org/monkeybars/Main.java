package org.monkeybars;

import java.io.BufferedInputStream;
import java.io.DataInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.util.ArrayList;
import org.jruby.RubyInstanceConfig;
import org.jruby.Ruby;

public class Main
{
    @SuppressWarnings("deprecation") // for the DataInputStream.readLine() call
    public static void main(String[] args) throws Exception
    {   
        RubyInstanceConfig config = new RubyInstanceConfig();
        Ruby runtime = Ruby.newInstance(config);
        runtime.getLoadService().init(new ArrayList(0));
        
        //TODO: Read this via getResource so it works from within a jar file
        ArrayList<String> lines = new ArrayList<String>();
        try
        {
            DataInputStream dis = new DataInputStream(new BufferedInputStream(new FileInputStream(new File("run_configuration"))));
        
            while(dis.available() != 0)
            {
                lines.add(dis.readLine());
            }
            dis = null;
        }
        catch(FileNotFoundException e)
        {
            System.err.println("Error loading run configuration file 'run_configuration'");
        }
                
        if(3 == lines.size())
        {
            System.setProperty("java.library.path",lines.get(2));
        }
        
        if(2 <= lines.size())
        {
            runtime.evalScriptlet("require 'java'\n" +
                    "$: << '" + lines.get(0) + "'\n" +
                    "begin\n" +
                    "require '" + lines.get(0) + "/" + lines.get(1) + "'\n" +
                    "rescue LoadError => e\n" +
                    "warn \"Error starting the application\"\n" +
                    "warn e\n" + 
                    "end"
                    );
        }
        else
        {
            System.err.println("Incorrect format for file 'run_configuration");
        }
    }
}