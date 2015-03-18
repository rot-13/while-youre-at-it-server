class NotificationsService

  @@gcm = GCM.new(ENV['GOOGLE_API_KEY'])

  def self.notify_users_on_trip(trip)
    potential_requesters = User.where('state <> ? AND notification_key IS NOT NULL', User.states[:tripping])
    Rails.logger.debug "Sending notification to #{potential_requesters.length} users"
    potential_requesters.to_a.each do |requester|
      response = @@gcm.send_with_notification_key(requester.notification_key, data: TripSerializer.new(trip).as_json, collapse_key: "trip_#{trip.id}")
      if response[:response] == 'success'
        Rails.logger.debug "Successfully sent notification to requester id #{requester.id} on trip with id: #{trip.id}"
      else
        Rails.logger.error "Failed to send notification to requester id #{requester.id} on trip with id: #{trip.id}, due to #{response[:body]}"
      end
    end
  end

  def self.notify_shopper_on_request(request)
    response = @@gcm.send_with_notification_key(request.trip.shopper.notification_key, data: NotificationSerializer.new(request).as_json)
    if response[:response] == 'success'
      Rails.logger.debug "Successfully sent notification on request with id: #{request.id}"
    else
      Rails.logger.error "Failed to send notification on request with id: #{request.id}, due to #{response[:body]}"
    end
  end

  def self.notify_requester_on_request(request)
    response = @@gcm.send_with_notification_key(request.user.notification_key, data: NotificationSerializer.new(request).as_json)
    if response[:response] == 'success'
      Rails.logger.debug "Successfully sent notification on request with id: #{request.id}"
    else
      Rails.logger.error "Failed to send notification on request with id: #{request.id}, due to #{response[:body]}"
    end
  end

  def self.register_user(user)
    registration_ids = user.devices.to_a.map(&:registration_id)
    return if registration_ids.blank?

    project_id = ENV['GOOGLE_PROJECT_ID']
    user.update!(notification_key_name: "shopingo_#{user.facebook_id}_#{DateTime.current.to_i}")

    response = @@gcm.create(user.notification_key_name, project_id, registration_ids)
    if response[:response] == 'success'
      notification_key = JSON.parse(response[:body])['notification_key']
      user.update!(notification_key: notification_key)
    else
      error = JSON.parse(response[:body])['error']
      raise StandardError.new('Could not register user for notifications: ' + error)
    end
  end

end