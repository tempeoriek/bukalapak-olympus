module Escrow
  class UpdateTransactionStatus
    include PostpaidTransactionUtility
    include ConnectionUtility
    include Action::PostpaidTransaction::Autoswitch

    URL = "#{Channel::Config::BUKALAPAK_ENDPOINT}_internal/remote/transactions".freeze

    def initialize(transaction)
      @transaction = transaction
      @bukalapak_state = TRX_STATE_TO_BL_STATE_MAP[@transaction.state]
    end

    def run!
      raise "state isn\'t found for `#{@transaction.state}` trx with remote id `#{@transaction.remote_transaction_id}`" unless @bukalapak_state
      remote_type = generate_remote_type(@transaction)
      payload = {
        remote_id: @transaction.id,
        buyer_id: @transaction.buyer_id,
        amount: @transaction.amount,
        remote_type: remote_type,
        state: @bukalapak_state
      }

      url = "#{URL}/#{remote_type}/#{@transaction.id}/status"
      response = Escrow::Connection.patch(url, payload)
      response = parse_response(response)

      finalize_transaction_state!
      update_revenue!

      log_success('update_transaction_status', url, payload, response, @transaction.id)
    rescue ::RestClient::Exception => e
      log_and_raise_error('update_transaction_status', url, payload, e.message, @transaction.id)
    end

    private

    def parse_response(response)
      JSON.parse(response).with_indifferent_access
    end

    def finalize_transaction_state!
      autoswitch_options = {}
      autoswitch_options[:operator_id] = @transaction.operator.id if @transaction.product_type == PDAM_PRODUCT

      if @transaction.partner_succeeded?
        record_autoswitch_value('refund_rate', :success, @transaction.product_type, autoswitch_options)

        @transaction.success!
      elsif @transaction.partner_failed?
        record_autoswitch_value('refund_rate', :failed, @transaction.product_type, autoswitch_options)

        @transaction.fail!
      elsif @transaction.cancelled?
        # TODO: well, cancel is final state, may change the if conditional
      else
        raise Exceptions::InvalidStatusError.new("Unexpected state #{@transaction.state} when updating remote state")
      end
    end

    def update_revenue!
      return unless transaction_has_revenue_fields?

      if @transaction.succeeded?
        ActiveRecord::Base.transaction do
          @transaction.revenue = biller_partner_revenue
          @transaction.revenue_at = Time.now
          @transaction.save!
        end
        tags = {
          product: @transaction.product_type,
          partner: @transaction.partner_name,
          transaction_type: @transaction.transaction_type,
        }
        Observer.distribution(Observer::Metric::REVENUE, @transaction.revenue, tags)
      end
    end

    def transaction_has_revenue_fields?
      @transaction.has_attribute?(:revenue) && @transaction.has_attribute?(:revenue_at)
    end

    def biller_partner_revenue
      case @transaction.product_type
      when BPJS_KESEHATAN_PRODUCT
        @transaction.partner_object.revenue
      when PDAM_PRODUCT
        [@transaction.pdam_bills&.count.to_i, 1].max * @transaction.operator.revenue
      when CREDIT_CARD_BILL_PRODUCT
        @transaction.partner.revenue
      else
        0
      end
    end
  end
end
