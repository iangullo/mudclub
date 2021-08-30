class UserMailer < ApplicationMailer
  default from: 'admin@bclub.org'

  def welcome_email
    @user = params[:user]
    @url  = 'https://tsalpa.org/login'
    mail(to: @user.email, subject: 'Bienvenido al CB Mairena')
  end
end
