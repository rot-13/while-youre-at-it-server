class UsersController < ApplicationController
  skip_before_action :require_user, only: [:login]

  def login
    unless @user = User.find_by(facebook_id: user_params[:facebook_id])
      @user = User.create(user_params)
    end
    render json: @user
  end

  def update
    @user = current_user.update(user_params)
    render json: @user
  end

  def state
    if current_user.active_trip
      outgoing_requests = current_user.active_trip.shop_requests.map do |shop_request|
        OutgoingRequestSerializer.new(shop_request)
      end
    else
      outgoing_requests = null
    end
    render json: {
      state: current_user.state, 
      active_trip: outgoing_requests,
      active_request: current_user.active_request 
    }
  end

  private

  def user_params
    params.permit(:facebook_id, :first_name, :last_name, :phone_number, :street_address, :city)
  end
end
