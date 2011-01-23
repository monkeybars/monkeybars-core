Monkeybars 1.1.1
[http://www.monkeybars.org](http://www.monkeybars.org)

Description
------------
  
Monkeybars is a library that enables you to interface (via JRuby) with and take advantage of Swing without writing any Java directly.  Using any editor you like, you create Java GUI elements and Monkeybars takes care of registering event listeners, receiving and handling events, updating your view from a model, etc. Monkeybars makes very few assumptions about your model or the structure of the code in your Java forms so it can be integrated into existing projects with a minimum of hassle.

Features/Problems:
------------

Needs more spec coverage.  But otherwise really quite cool.


Synopsis
---------


Mailing list, downloads and bug reports

The source is hosted on GitHub: [http://github.com/monkeybars/monkeybars-core](http://github.com/monkeybars/monkeybars-core)

The mailing list is [http://groups.google.com/group/monkeybars-mvc](http://groups.google.com/group/monkeybars-mvc)

Issues are on Pivotal Tracker: [http://www.pivotaltracker.com/projects/118006](http://www.pivotaltracker.com/projects/118006) 


Questions or comments? Contact [James Britt](mailto:james+monkeybars@neurogami.com)

 
Requirements
---------

  Java 1.6, Rake, JRuby 1.5 or later.

Installation
---------

There are three ways to obtain Monkeybars.  
  - Source distribution
  - Gem which includes a project generator, ideal for new projects
  - Jar file for integration into existing Java applications

The most current gem can be installed from `gems.neurogami.com`

    sudo gem sources -a http://gems.neurogami.com

or

    sudo gem i monkeybars ––source http://gems.neurogami.com


License
--------
Monkeybars is licensed under the Ruby licence (as on January 2010); see COPYING.txt.

Attribution
---------

Monkeybars is the work of many contributors.

- David Koontz - Core contributor, original author, tutorials
- Logan Barnett - Core contributor, nested views, signals, many bug fixes
- [James Britt](http://www.jamesbritt.com) - Core contributor, project manager, fixes to documentation, build process, nested view bugs
- Mario Aquino - Listener registration, Foxtrot integration, many bug fixes and specs


Feed your head.
