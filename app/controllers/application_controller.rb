# frozen_string_literal: true

class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Basic::ControllerMethods
  include PostpaidTransactionUtility

  before_action :latency_start_time
  after_action :log_request, except: [:healthz]
  after_action :trace_latency
  rescue_from StandardError, with: :error_handler

  PRODUCT_NAME = nil
  DEFAULT_ERR_IDX = 5

  USER_TYPE = {
    '0': 'user',
    '1': 'agent'
  }.freeze
  DEFAULT_USER_TYPE = 'internal'
  PLATFORM_MITRA = 'mitra_android_app'.freeze

  def healthz
    render json: 'ok', status: 200
  end

  def request_context
    @context ||= ::Context.new do |context|
      context.actor = request.env['HTTP_AUTHORIZATION']
      context.trace_sampled = true
      context.client = ::Client.new(decoded_token[:application_name], request.headers['Bukalapak-App-Version']) if decoded_token
    end
  end

  protected

  def created_on_platform
    client_platform = request_context&.full_context_hash.dig(:client_platform)
    return nil unless client_platform.present?

    client_platform == PLATFORM_MITRA ? MITRA_PLATFORM : MARKETPLACE_PLATFORM
  end

  def transaction_type
    if decoded_token.dig(:resource_owner, :o2o_agent, :status) == 'confirmed'
      AGENT_USER_TRANSACTION_TYPE
    else
      NORMAL_USER_TRANSACTION_TYPE
    end
  end

  def buyer_type
    if decoded_token.dig(:resource_owner, :o2o_agent, :status) == 'confirmed'
      AGENT_BUYER_TYPE
    else
      NORMAL_BUYER_TYPE
    end
  end

  def decoded_token
    return @decoded_token if @decoded_token
    token   = request.env['HTTP_AUTHORIZATION']
    pattern = /^Token /
    token   = token.gsub(pattern, '') if token && token.match(pattern)

    @decoded_token = JsonWebToken.decode(token)
  end

  def log_request
    return if request.method == 'GET'

    tags = %w[olympus incoming request]
    tags << 'error' if @is_error
    action = request_controller
    log_entry = request_context.full_context_log_entry(
      request_status,
      tags,
      action: action,
      duration: latency_duration,
      request_bl_service: request_bl_service,
      payload: params,
      track_id: params[:id]
    )
    Logger2.info(log_entry)
  end

  def username
    decoded_token&.dig('resource_owner', 'username')
  end

  def response_code
    @response_code || 200
  end

  def request_controller
    params[:controller] + '#' + params[:action]
  end

  def request_status
    return 'fail' if @is_error

    'ok'
  end

  def latency_start_time
  	@latency_start_time ||= ::Time.now
  end

  def latency_end_time
  	@latency_end_time ||= ::Time.now
  end

  def latency_duration
    latency_end_time - latency_start_time
  end

  def request_bl_service
    request.env['HTTP_BL_SERVICE']
  end

  def trace_latency
    route = url_for.gsub(/https?:\/\//, '')
    route = route.gsub(/[0-9]+/, 'id')
    trx_type = decoded_token ? USER_TYPE[transaction_type.to_s.to_sym] : DEFAULT_USER_TYPE
    product = self.class::PRODUCT_NAME

    metric_labels = {
      status: request_status,
      route: route,
      method: request.method,
      transaction_type: trx_type,
      product: product,
      http_code: response_code,
      created_on: created_on_platform
    }

    Observer.histogram(Observer::Metric::API, latency_duration, metric_labels)
  end

  def error_handler(e)
    @is_error = true unless e.is_a?(Exceptions::PostpaidError)
    @response_code = e.http_code rescue '500'
    trace_latency

    tags = %w[olympus incoming request error]
    action = request_controller
    metric_labels = {
      request_bl_service: request_bl_service,
      duration: latency_duration,
      http_code: @response_code,
      exception: e.class,
      backtrace: e&.backtrace&.take(DEFAULT_ERR_IDX),
      action: action
    }

    log_entry = request_context.log_entry(e.message, tags, metric_labels)
    Logger2.error(log_entry)

    case
    when (is_remapped_inquiry_error(e))
      return render_inquiry_error(e)
    when (e.is_a?(Exceptions::PostpaidError) || e.is_a?(Exceptions::InternalError))
      return render_error(e)
    end

    Honeybadger.notify(e)

    render_error(Exceptions::DefaultError.new)
  end

  def validate_params(required_params)
    return if required_params.empty?
    required_params.each do |required_param|
      raise ::Exceptions::MissingParameter.new if params[required_param].blank?
    end
  end

  private

  def is_remapped_inquiry_error(e)
    remapped_products = %w[pdam electricity_postpaids bpjs_kesehatan]

    return e.is_a?(Exceptions::PostpaidError) &&
      params[:action] == 'inquiries' &&
      remapped_products.include?(params[:controller])
  end
end
