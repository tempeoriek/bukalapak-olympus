module Escrow
  class SendNotification
    include PostpaidTransactionUtility
    include ConnectionUtility
    URL = "#{Channel::Config::BUKALAPAK_ENDPOINT}_internal/notifications/postpaid_emails".freeze

    def initialize(transaction)
      @transaction = transaction
      @template = EMAIL_TEMPLATE[@transaction.class][@transaction.state]

      raise "Unsupported trx class `#{@transaction.class}` or state `#{@transaction.state}`" unless @template
    end

    def run!
      remote_type = generate_remote_type(@transaction)
      payload = generate_payload_notification
      response = Escrow::Connection.post(URL, payload)
      response = parse_response(response)
      log_success('send_notification', URL, payload, response, @transaction.id)
    rescue ::RestClient::Exception => e
      log_and_raise_error('send_notification', URL, payload, e.message, @transaction.id)
    end

    private

    def parse_response(response)
      JSON.parse(response).with_indifferent_access
    end

    def generate_payload_notification
      payload = {
        template: @template,
        user_ids: [@transaction.buyer_id]
      }

      if @transaction.product_type == ELECTRICITY_PRODUCT
        payload[:postpaid_electricity_payload] = [electricity_postpaid_payload]
      elsif @transaction.product_type == BPJS_KESEHATAN_PRODUCT
        payload[:bpjs_kesehatan_payload] = [bpjs_kesehatan_payload]
      elsif @transaction.product_type == PDAM_PRODUCT
        payload[:pdam_payload] = [pdam_payload]
      elsif @transaction.product_type == PHONE_CREDIT_PRODUCT
        payload[:phone_credit_postpaid_payload] = [phone_credit_postpaid_payload]
      elsif @transaction.product_type == CREDIT_CARD_BILL_PRODUCT
        payload[:credit_card_bill_payload] = [credit_card_bill_payload]
      elsif @transaction.product_type == 'vehicle-tax'
        payload[:vehicle_tax_payload] = [vehicle_tax_payload]
      else
        raise "Unsupported Type"
      end

      payload
    end

    def electricity_postpaid_payload
      {
        remote_id: @transaction.remote_transaction_id,
        customer_number: @transaction.customer_number,
        customer_name: @transaction.customer_name,
        segmentation: @transaction.segmentation,
        power: @transaction.power,
        period: @transaction.period,
        amount: @transaction.amount,
        admin_charge: @transaction.admin_charge,
        penalty_fee: @transaction.penalty_fee,
        stand_meter: @transaction.stand_meter,
        info_text: @transaction.info_text,
        reference_number: @transaction.reference_number,
        partner_name: @transaction.partner,
        outstanding_bill: @transaction.outstanding_bill,
        unpaid_bill: @transaction.unpaid_bill
      }
    end

    def bpjs_kesehatan_payload
      {
        remote_id: @transaction.remote_transaction_id,
        customer_number: @transaction.customer_number,
        customer_name: @transaction.customer_name,
        branch_name: @transaction.branch_name,
        admin_charge: @transaction.admin_charge,
        family_member_count: @transaction.family_member_count,
        payment_period: @transaction.payment_period,
        paid_until: @transaction.paid_until,
        family_members: @transaction.family_members.as_json,
        info: @transaction.info,
        reference_number: @transaction.reference_number,
        partner_name: @transaction.partner
      }
    end

    def pdam_payload
      period = @transaction.period
      payload = {
        remote_id: @transaction.remote_transaction_id,
        operator_name: @transaction.pdam_operator.name,
        customer_number: @transaction.customer_number,
        customer_name: @transaction.customer_name,
        amount: @transaction.amount,
        usage: @transaction.usage,
        start_period: period.first,
        end_period: period.last,
        address: @transaction.address,
        admin_charge: @transaction.admin_charge,
        bills: @transaction.pdam_bills.as_json
      }
      payload.merge!(@transaction.start_end_usage_meter)
    end

    def phone_credit_postpaid_payload
      {
        remote_id: @transaction.remote_transaction_id,
        customer_number: @transaction.phone_number,
        customer_name: @transaction.customer_name,
        provider_name: @transaction.provider.provider,
        provider_product_name: @transaction.provider.product_name,
        reference_no: @transaction.reference_no,
        start_period: @transaction.start_bill_period,
        end_period: @transaction.end_bill_period
      }
    end

    def credit_card_bill_payload
      {
        remote_id: @transaction.remote_transaction_id,
        biller_name: @transaction.biller.name,
        customer_number: @transaction.customer_number,
        customer_name: @transaction.customer_name,
        due_date: @transaction.bill_period,
        admin_charge: @transaction.admin_charge
      }
    end

    def vehicle_tax_payload
      bill_hash = @transaction.bill.as_json.to_h.deep_symbolize_keys!
      {
        remote_id: @transaction.remote_transaction_id,
        bill_code: @transaction.bill_code,
        admin_charge: @transaction.admin_fee.to_i,
        partner_charge: @transaction.partner_fee.to_i,
        amount: @transaction.amount,
        ntb: @transaction.ntb
      }.merge(bill: bill_hash.except(:amount).merge(bill_hash.dig(:amount, :details).to_h))
    end
  end
end
