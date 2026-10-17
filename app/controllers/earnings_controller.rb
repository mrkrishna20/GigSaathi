class EarningsController < ApplicationController
  PER_PAGE = 20

  def index
    @earnings = Earning.ordered.limit(PER_PAGE)
    @earning = Earning.new(work_date: Date.current)
  end

  def create
    @earning = Earning.new(earning_params)

    if @earning.save
      redirect_to earnings_path, notice: "Your earnings entry has been saved."
    else
      @earnings = Earning.ordered.limit(PER_PAGE)
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    Earning.find(params[:id]).destroy!
    redirect_to earnings_path, notice: "The earnings entry has been deleted."
  end

  private

  def earning_params
    params.require(:earning).permit(:work_date, :total_earnings, :fuel_expenses, :food_expenses, :other_expenses)
  end
end
