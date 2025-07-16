module ConnectionUtility
  def log_and_raise_error(action, url, payload, response, track_id)
    message = {
      url: url,
      payload: payload,
      response: response
    }.to_s
    tags = ['bukalapak', action, 'failed']
    log_request(tags, message, track_id)
    raise Exceptions::BukalapakConnectionError.new(response)
  end

  def log_success(action, url, payload, response, track_id)
    message = {
      url: url,
      payload: payload,
      response: response
    }.to_s
    tags = ['bukalapak', action, 'success']
    log_request(tags, message, track_id)
  end
end
