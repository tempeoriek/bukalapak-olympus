# frozen_string_literal: true

module Internal
  class ElectricityPostpaidsController < Internal::PostpaidController
    include Response
    include Authenticate
    include Postpaid::Constant

    PRODUCT_NAME = ELECTRICITY_PRODUCT
    CUSTOMER_NUMBER_DIGIT_REQUIRED = 12
    AGENT_TYPE_BL_SERVICES = %w[middleman]

    def inquiries
      return unless http_basic_authenticate == true

      raise ::Exceptions::InvalidParameterError.new("ID Pelanggan tidak boleh kosong") unless params[:customer_number]
      raise ::Exceptions::InvalidParameterError.new("ID Pelanggan maks. #{CUSTOMER_NUMBER_DIGIT_REQUIRED} digit") unless params[:customer_number].length == CUSTOMER_NUMBER_DIGIT_REQUIRED

      partner = ::Toggles::ElectricityPostpaidInternalUsePartner.active? ? params[:partner] : nil
      form    = Form::ElectricityPostpaid.new(params[:customer_number], Form::ElectricityPostpaid::DEFAULT_USERNAME, partner, determine_buyer_type_by_bl_service)

      raise Exceptions::PartnerNotFound.new('Maaf, lagi ada gangguan. Coba sebentar lagi ya.') unless form.partner_object

      action = Action::PostpaidTransaction::Inquiry.new(form)
      result = action.run!
      render_response(electricity_inquiry_format(result), 200)
    end

    def create
      return unless http_basic_authenticate == true

      raise ::Exceptions::InvalidParameterError.new("ID Pelanggan tidak boleh kosong") unless params[:customer_number]
      raise ::Exceptions::InvalidParameterError.new("ID Pelanggan maks. #{CUSTOMER_NUMBER_DIGIT_REQUIRED} digit") unless params[:customer_number].length == CUSTOMER_NUMBER_DIGIT_REQUIRED

      raise Exceptions::UnauthorizedUser.new if params[:buyer_id].blank?

      buyer_id = params[:buyer_id]
      transaction_type = params[:transaction_type].blank? ? BUKA_PENGADAAN_BUYER_TYPE : params[:transaction_type]

      partner = ::Toggles::ElectricityPostpaidInternalUsePartner.active? ? params[:partner] : nil
      form    = Form::ElectricityPostpaid.new(params[:customer_number], Form::ElectricityPostpaid::DEFAULT_USERNAME, partner, transaction_type, params[:mass_bill_id])

      action = Action::ElectricityTransaction::Create.new(form, buyer_id, transaction_type)
      transaction = action.run!
      render_response(::Serializer::Internal::ElectricityPostpaidTransaction::Create.new(transaction).as_json, 201)
    rescue Exceptions::PostpaidError => e
      render_error(e)
    end

    def show
      # basic authentication for mothership
      authenticated = http_basic_authenticate
      # this is to avoiding double render
      return unless authenticated == true

      transaction = PostpaidTransaction.find_by_id(params[:id])
      raise Exceptions::TransactionNotFound.new unless transaction.present?

      render_response(Serializer::Internal::ElectricityPostpaidTransaction::Show.new(transaction).as_json, 200)
    end

    def resend_email
      # basic authentication for mothership
      authenticated = http_basic_authenticate
      # this is to avoiding double render
      return unless authenticated == true

      transaction = PostpaidTransaction.find_by(remote_transaction_id: params[:id])
      raise Exceptions::TransactionNotFound.new unless transaction.present?

      raise Exceptions::InvalidStatusError.new unless transaction.state == TRANSACTION_SUCCEEDED

      send_email(transaction)

      render_response({message: 'success'}, 202)
    end

    def get_partners
      result = []
      return unless http_basic_authenticate == true

      ElectricityPostpaidPartner.all.each do |partner|
        result << Serializer::Internal::ElectricityPostpaidPartner::Show.new(partner)
      end

      render_response(result, HTTP_STATUS_OK)
    end

    def status
      super {
        |id|
          PostpaidTransaction.find_by_id(id)
      }
    end

    private

    def send_email(transaction)
      payload = {
        remote_id: transaction.remote_transaction_id,
        product_type: transaction.product_type
      }
      GcpsPublisher.publish(Subscribers::Topics::EMAIL_NOTIF, payload, track_id: payload[:remote_id])
    end

    def determine_buyer_type_by_bl_service
      if AGENT_TYPE_BL_SERVICES.include? request_bl_service
        COLLECTING_AGENT_BUYER_TYPE
      else
        NORMAL_BUYER_TYPE
      end
    end
  end
end
