class EarningsController < ApplicationController
  PER_PAGE = 20

  before_action :require_authentication

  def index
    @page = page_number
    load_earnings
    @earning = Earning.new(work_date: Date.current)
  end

  def create
    @earning = current_user.earnings.new(earning_params)

    if @earning.save
      redirect_to earnings_path, notice: "Your earnings entry has been saved."
    else
      @page = 1
      load_earnings
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    current_user.earnings.find(params[:id]).destroy!
    redirect_to earnings_path, notice: "The earnings entry has been deleted."
  end

  private

  def earning_params
    params.require(:earning).permit(:work_date, :total_earnings, :fuel_expenses, :food_expenses, :other_expenses)
  end

  def page_number
    page = params[:page].to_s
    page.match?(/\A\d{1,6}\z/) ? [ page.to_i, 1 ].max : 1
  end

  def load_earnings
    page_entries = current_user.earnings.ordered.offset((@page - 1) * PER_PAGE).limit(PER_PAGE + 1).to_a
    @has_next_page = page_entries.length > PER_PAGE
    @has_previous_page = @page > 1
    @earnings = page_entries.first(PER_PAGE)
  end
end
