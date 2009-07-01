require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "Command Line" do
  before :all do
    @command = "jruby #{File.join(File.dirname(__FILE__), '..', '..', 'bin', 'monkeybars')} -RI--no-download spec-tmp-proj"
    @temp_project_dir = File.join(File.dirname(__FILE__), '..', '..', 'spec-tmp-proj')
    FileUtils.rm_rf(@temp_project_dir)
    `#{@command}`
  end

  after :all do
    FileUtils.rm_rf(@temp_project_dir)
  end

  it "creates a Rakefile that uses Rawr" do
    
    File.should be_exist(File.join(@temp_project_dir, 'Rakefile'))
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
    pending
  end
end