class ShopRequestsController < ApplicationController
  before_action :ensure_idle, only: [:create]
  before_action :ensure_can_respond, only: [:accept, :decline]
  before_action :ensure_owner, only: [:cancel, :settle]

  def create
    trip = User.find_by(facebook_id: params.require(:shopper_id)).active_trip
    request = current_user.shop_requests.create(request_params.merge(trip: trip))
    current_user.requesting!

    NotificationsService.notify_shopper_on_request(request)
    render json: request
  end

  def index
    requests = current_user.active_trip.shop_requests
    render json: requests, each_serializer: IncomingRequestSerializer
  end

  def accept
    current_request.accepted!
    render_success
  end

  def decline
    current_request.declined!
    current_request.user.idle!
    render_success
  end

  def cancel
    current_user.active_request.canceled!
    current_user.idle!
    render_success
  end

  def settle
    current_user.active_request.settled!
    current_user.idle!
    render_success
  end

  private

  def current_request
    @_shop_request ||= ShopRequest.find(params.require(:request_id))
  end

  def request_params
    params.permit(:offer, items: [])
  end

  def ensure_idle
    unless current_user.idle?
      render_error 'You can not request now', :bad_request
    end
  end

  def ensure_tripping
    unless current_user.tripping?
      render_error 'You are not on a trip right now', :bad_request
    end
  end

  def ensure_can_respond
    if current_request.trip.shopper != current_user
      render_error 'You can not respond to this request', :forbidden
    end
  end

  def ensure_owner
    if current_request.user != current_user
      render_error 'You can not change the status of this request', :forbidden
    end
  end
end
