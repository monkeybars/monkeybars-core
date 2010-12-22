This a simple(In fact not so simple) example for people who is new to Monkeybars.
It's not recommended use this as your Hello World Monkeybars app.


In this example, you can learn:
1. How to create multiple main frame when you need via a menu item.
2. How to create a monkeybars cotrol and add it into the Main control as nested control.
3. How to synchorize JTextPanel in two sub nested controls which are created dynamically.
4. How to popup a modal JDialog with owner(Modal JDialog is a pain in Monkeybars).
   And you can still use Monkeybars to deal with the action in the JDialog content panel.
5. How to use a filechooser to select a file.


About the Diff algorithm. I'm using diff-lcs (1.1.2) as the diff algorithm. You can install
it via: jruby -S gem install diff-lcs
I also comment out line 434 of the diff/lcs.rb to make sure the finished_a function
will be called.
I just display the difference based on lines. And make sure the same line in both file will be
displayed on the same line by adding some blank lines.


Although this is just a simple example to show how to use Monkeybars. You can extend it to
make it work more well.
ToDo:
1. Add line numbers to both diff panel, so you can know which line is in the original file.
2. Compare the different lines byte by byte instead of just display the different lines.
3. Add a preference dialog, so you can change the color of the different text.



If you meet any problem with make this example working or have any question about Monkeybar,
please post your message at:  http://groups.google.com/group/monkeybars

Author:   daiwhea@gmail.com
About me: I'm new to both Jruby and Monkeybars. But I feel they are more interesting
          and fun. When I dive into Monkeybars, I found there is few examples
          which I can study. So I made this small example and wish it will help
          the newbie a little.