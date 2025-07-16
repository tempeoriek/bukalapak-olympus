module Services
  class AnonymizationData
    include PostpaidTransactionUtility

    PRODUCTS = [ELECTRICITY_PRODUCT, BPJS_KESEHATAN_PRODUCT, PDAM_PRODUCT, PHONE_CREDIT_PRODUCT, CREDIT_CARD_BILL_PRODUCT, BPJS_KETENAGAKERJAAN_PRODUCT].freeze
    ANONYMIZED_FIELDS_MAP = {
      ELECTRICITY_PRODUCT => %w[customer_name],
      BPJS_KESEHATAN_PRODUCT => %w[customer_name customer_number phone_number],
      BPJS_KETENAGAKERJAAN_PRODUCT => %w[customer_number customer_name],
      PDAM_PRODUCT => %w[customer_name address],
      PHONE_CREDIT_PRODUCT => %w[customer_name phone_number],
      CREDIT_CARD_BILL_PRODUCT => %w[customer_name customer_number]
    }

    RECURRENCES_KLASS_MAP = {
      ELECTRICITY_PRODUCT => ::ElectricityPostpaidRecurrenceTemplateDetail, # customer_name
      PHONE_CREDIT_PRODUCT => ::PhoneCreditPostpaidRecurrenceTemplateDetail, # customer_name, phone_number
      BPJS_KESEHATAN_PRODUCT => ::BpjsKesehatanRecurrenceTemplateDetail, # customer_name, customer_number, phone_number
      PDAM_PRODUCT => ::PdamRecurrenceTemplateDetail # customer_name
    }

    def initialize(buyer_id)
      @buyer_id = buyer_id
    end

    def perform
      PRODUCTS.each do |product|
        anonymization(product)
        recurrence_anonymization(product)
      end
    rescue StandardError => e
      Logger2.error(
        {
          tags: %W[anonymization_data error],
          backtrace: e&.backtrace.take(7).join("\n"),
          message: e.message,
          track_id: @buyer_id
        }
      )

      raise e
    end

    private

    def anonymized
      @anonymized ||= "DeletedUser-#{SecureRandom.uuid}"
    end

    def anonymization(transaction_type)
      transactions = PRODUCT_TO_TRX_KLASS_MAP[transaction_type].where(buyer_id: @buyer_id)

      fields = ANONYMIZED_FIELDS_MAP[transaction_type]
      attrs  = {}
      transactions.find_each do |transaction|
        fields.each do |field|
          attrs["#{field}"] = anonymized
        end

        transaction.update_columns(attrs)
      end

      bpjs_kesehatan_family_member_anonymization(transactions.pluck(:id)) if transaction_type == BPJS_KESEHATAN_PRODUCT
    end

    def recurrence_anonymization(transaction_type)
      recurrence_klass = RECURRENCES_KLASS_MAP[transaction_type]
      return if recurrence_klass.nil?

      recurrences = recurrence_klass.where(buyer_id: @buyer_id)

      fields = case transaction_type
        when PDAM_PRODUCT
          %w[customer_name]
        when PHONE_CREDIT_PRODUCT
          %w[customer_name customer_number]
        else
          ANONYMIZED_FIELDS_MAP[transaction_type]
      end

      attrs = {}
      recurrences.find_each do |recurrence|
        fields.each do |field|
          attrs["#{field}"] = anonymized
        end

        recurrence.update_columns(attrs)
      end
    end

    def bpjs_kesehatan_family_member_anonymization(transaction_ids)
      return if transaction_ids.empty?

      members = ::BpjsKesehatanFamilyMember.where(bpjs_kesehatan_transaction_id: transaction_ids)
      members.find_each do |member|
        attrs = {
          name: anonymized,
          member_number: anonymized
        }

        member.update_columns(attrs)
      end
    end
  end
end
