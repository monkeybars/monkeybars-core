require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "Command Line" do
  before :each do
    @command = "jruby #{File.join(File.dirname(__FILE__), '..', '..', 'bin', 'monkeybars')} -RI--no-download spec-tmp-proj"
    @temp_project_dir = File.join(File.dirname(__FILE__), '..', '..', 'spec-tmp-proj')
    FileUtils.rm_rf(@temp_project_dir)
  end

  after :each do
    #FileUtils.rm_rf(@temp_project_dir)
  end

  it "creates a Rakefile that uses Rawr" do
    `#{@command}`

    File.should be_exist(File.join(@temp_project_dir, 'Rakefile'))
    File.read(File.join(@temp_project_dir, 'Rakefile')).should match(/require 'rawr'/)
  end

  it "creates a Rakefile that loads additional Rake tasks from the tasks dir" do
    puts `#{@command}`

    File.should be_exist(File.join(@temp_project_dir, 'Rakefile'))
    File.read(File.join(@temp_project_dir, 'Rakefile')).should match(/Dir\.glob/)
    File.read(File.join(@temp_project_dir, 'Rakefile')).should match(/tasks/)
  end

  it "places monkeybars windows and mac icons in the icons dir" do
    pending
  end
end