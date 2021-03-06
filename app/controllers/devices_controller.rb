class DevicesController < ApplicationController

  def create
    device = current_user.devices.find_or_create_by!(device_params)
    NotificationsService.register_user(current_user) if current_user.notification_key.blank?

    respond_to do |format|
      format.json { render json: device }
    end
  end

  private

  def device_params
    params.require('device').permit(:registration_id)
  end

end