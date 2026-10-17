class UsersController < ApplicationController
  rate_limit to: 5, within: 1.hour, only: :create, with: :signup_rate_limit_exceeded

  def new
    return redirect_to earnings_path if current_user

    @user = User.new
  end

  def create
    if current_user
      redirect_to earnings_path
      return
    end

    @user = User.new(user_params)

    if @user.save
      reset_session
      session[:user_id] = @user.id
      redirect_to earnings_path, notice: "Your account is ready. Welcome to GigSaathi."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end

  def signup_rate_limit_exceeded
    @user = User.new
    @error = "Too many accounts were created from this connection. Please try again later."
    render :new, status: :too_many_requests
  end
end
