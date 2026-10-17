class SessionsController < ApplicationController
  rate_limit to: 5, within: 15.minutes, only: :create, with: :login_rate_limit_exceeded

  def new
    redirect_to earnings_path if current_user
  end

  def create
    email = params[:email].to_s.strip.downcase
    password = params[:password].to_s
    user = User.find_by(email: email) if email.bytesize <= 254 && password.bytesize <= 72

    if user&.authenticate(password)
      reset_session
      session[:user_id] = user.id
      redirect_to earnings_path, notice: "You are signed in."
    else
      @email = email
      @error = "Email or password is incorrect."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "You are signed out."
  end

  private

  def login_rate_limit_exceeded
    @error = "Too many sign-in attempts. Please wait 15 minutes and try again."
    render :new, status: :too_many_requests
  end
end
