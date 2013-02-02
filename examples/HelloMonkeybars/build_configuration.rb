configuration do |c|
	# The name for your resulting application file (e.g., if the project_name is 'foo' then you'll get foo.jar, foo.exe, etc.)
	# default value: "HelloMonkeybars"
	#
	#c.project_name = "HelloMonkeybars"

	# Undocumented option 'output_dir'
	# default value: "package"
	#
	#c.output_dir = "package"

	# The main ruby file to invoke, minus the .rb extension
	# default value: "main"
	#
	#c.main_ruby_file = "main"

	# The fully-qualified name of the main Java file used to initiate the application.
	# default value: "org.rubyforge.rawr.Main"
	#
	#c.main_java_file = "org.rubyforge.rawr.Main"

	# A list of directories where source files reside
	# default value: ["src"]
	#
	#c.source_dirs = ["src"]

	# A list of regexps of files to exclude
	# default value: []
	#
	#c.source_exclude_filter = []

	# Whether Ruby source files should be compiled into .class files
	# default value: true
	#
	#c.compile_ruby_files = true

	# A list of individual Java library files to include.
	# default value: []
	#
	#c.java_lib_files = []

	# A list of directories for rawr to include . All files in the given directories get bundled up.
	# default value: ["lib/java"]
	#
	#c.java_lib_dirs = ["lib/java"]

	# Undocumented option 'files_to_copy'
	# default value: []
	#
	#c.files_to_copy = []

	# Undocumented option 'target_jvm_version'
	# default value: 1.6
	#
	c.target_jvm_version = 1.7

	# Undocumented option 'jvm_arguments'
	# default value: ""
	#
	#c.jvm_arguments = ""

	# Undocumented option 'java_library_path'
	# default value: ""
	#
	#c.java_library_path = ""

	# Undocumented option 'extra_user_jars'
	# default value: {}
	#
	#c.extra_user_jars[:data] = { :directory => 'data/images/png',
	#                             :location_in_jar => 'images',
	#                             :exclude => /*.bak$/ }

	# Undocumented option 'mac_do_not_generate_plist'
	# default value: nil
	#
	#c.mac_do_not_generate_plist = nil

	# Undocumented option 'mac_icon_path'
	# default value: nil
	#
	#c.mac_icon_path = nil

	# Undocumented option 'windows_icon_path'
	# default value: nil
	#
	#c.windows_icon_path = nil

  c.mac_icon_path = File.expand_path('icons/monkeybars.icns')
  c.windows_icon_path = File.expand_path('icons/monkeybars.ico')
end

