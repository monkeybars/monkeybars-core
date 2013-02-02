require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "Command Line" do
  before :all do
    base_folder = File.expand_path File.join( File.dirname(__FILE__), '..', '..' )
    @command = "jruby #{File.join(base_folder, 'bin', 'monkeybars')} -RI--no-download spec-tmp-proj"
    @temp_project_dir = File.join(base_folder, 'spec-tmp-proj')
    FileUtils.rm_rf(@temp_project_dir)
   puts @command
   File.open( "spec-cli.txt", 'w'){ |f|
     f.puts  @command
   
   }
   puts `#{@command}`
  end

  after :all do
    FileUtils.rm_rf(@temp_project_dir)
  end

  it "creates a Rakefile that uses Rawr" do
    
    File.should be_exist @temp_project_dir
    File.should be_exist File.join(@temp_project_dir, 'Rakefile')
    File.read(File.join(@temp_project_dir, 'Rakefile')).should match(/require 'rawr'/)
  end

  it "creates a Rakefile that loads additional Rake tasks from the tasks dir" do
    File.should be_exist(File.join(@temp_project_dir, 'Rakefile'))
    File.read(File.join(@temp_project_dir, 'Rakefile')).should match(/Dir\.glob/)
    File.read(File.join(@temp_project_dir, 'Rakefile')).should match(/tasks/)
  end

  it "places monkeybars windows and mac icons in the icons dir" do
    File.should be_exist(File.join(@temp_project_dir, 'icons', 'monkeybars.icns'))
    File.should be_exist(File.join(@temp_project_dir, 'icons', 'monkeybars.ico'))
  end

  it "uses the icons in the build_configuration.rb" do
    File.read(File.join(@temp_project_dir, 'build_configuration.rb')).should match(/monkeybars\.icns/)
    File.read(File.join(@temp_project_dir, 'build_configuration.rb')).should match(/monkeybars\.ico/)
  end
end