class ApplicationController < Monkeybars::Controller
  # Add content here that you want to be available to all the controllers
  # in your application
  # we use this to show some message to the user.
  def show_msg(title, message)
    title ||= 'The title of the default message.'
    message ||= "Some message you should know."
    javax.swing.JOptionPane.show_message_dialog(nil, message, title,
      javax.swing.JOptionPane::DEFAULT_OPTION)
  end
end