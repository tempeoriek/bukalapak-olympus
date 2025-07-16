# frozen_string_literal: true

RSpec.shared_context 'thor_lets', shared_context: :metadata do
  let(:unauthorized_response) do
    {
      "errors": [
        {
          "message": 'you are not authorized to do this action',
          "code": 'UNAUTHORIZED'
        }
      ]
    }
  end

  let(:forbidden_response) do
    {
      "errors": [
        {
          "message": 'you do not have permission to do this action',
          "code": 'FORBIDDEN'
        }
      ]
    }
  end

  # PDAM
  let(:success_inquiry_response) do
    {
      "water_bill_customer": {
        "customer_number": '19989000000',
        "customer_name": 'JUNAIDI XX001',
        "penalty_fee": '0',
        "currency": 'IDR',
        "total_price": '105000',
        "admin_charge": '1000',
        "start_bill_period": '2012-01-01',
        "end_bill_period": '2012-01-01',
        "usage": '56',
        "address": 'Jalan Ampera Raya No. 22',
        "start_usage_meter": '402',
        "end_usage_meter": '458',
        "operator": {
          "name": 'Denpasar',
          "terms_and_conditions": 'Tagihan bisa dibayar pada tanggal tertentu, jika pembayaran dilakukan pada tanggal tutup maka pembayaran akan dilakukan di hari buka setelahnya'
        },
        "sub_segment": "GOL 3A",
        "bills": [
          {
            "period": '2012-01-01',
            "penalty_fee": '0',
            "amount": '104000',
            "usage": '56',
            "cubication": '402-458',
            "stamp_duty": '3000',
            "waste": '1000'
          }
        ],
        "response_code": '0000',
        "message": 'successful'
      }
    }.with_indifferent_access
  end

  let(:success_inquiry_multiple_bill_response) do
    {
      "water_bill_customer": {
        "customer_number": '19989000000',
        "customer_name": 'JUNAIDI XX001',
        "penalty_fee": '0',
        "currency": 'IDR',
        "total_price": '212000',
        "admin_charge": '2000',
        "start_bill_period": '2012-01-01',
        "end_bill_period": '2012-01-01',
        "usage": '56',
        "address": 'Jalan Ampera Raya No. 22',
        "start_usage_meter": '402',
        "end_usage_meter": '458',
        "operator": {
          "name": 'Denpasar',
          "terms_and_conditions": 'Tagihan bisa dibayar pada tanggal tertentu, jika pembayaran dilakukan pada tanggal tutup maka pembayaran akan dilakukan di hari buka setelahnya'
        },
        "sub_segment": "GOL 3A",
        "bills": [
          {
            "period": '2012-01-01',
            "penalty_fee": '0',
            "amount": '104000',
            "usage": '56',
            "cubication": '402-458',
            "stamp_duty": '3000',
            "waste": '1000'
          },
          {
            "period": '2012-02-01',
            "penalty_fee": '0',
            "amount": '106000',
            "usage": '56',
            "cubication": '458-600',
            "stamp_duty": '4000',
            "waste": '2000'
          }
        ],
        "response_code": '0000',
        "message": 'successful'
      }
    }.with_indifferent_access
  end

  let(:failed_inquiry_response) do
    {
      "water_bill_customer": {
        "customer_number": '19989000000',
        "customer_name": 'JUNAIDI XX001',
        "penalty_fee": '',
        "currency": 'IDR',
        "total_price": '0',
        "admin_charge": '',
        "start_bill_period": '',
        "end_bill_period": '',
        "usage": '',
        "address": '',
        "start_usage_meter": '',
        "end_usage_meter": '',
        "operator": nil,
        "bills": [],
        "response_code": '0014',
        "message": 'unknown number'
      }
    }.with_indifferent_access
  end

  let(:success_create_transaction_response) do
    {
      "water_bill_transaction": {
        "customer_number": '19989000000',
        "customer_name": 'JUNAIDI XX001',
        "penalty_fee": '0',
        "currency": 'IDR',
        "total_price": '14110',
        "admin_charge": '1000',
        "start_bill_period": '2012-01-01',
        "end_bill_period": '2012-01-01',
        "usage": '56',
        "address": 'Jalan Ampera Raya No. 22',
        "start_usage_meter": '402',
        "end_usage_meter": '458',
        "reference_number": '12345',
        "operator": {
          "name": 'Denpasar',
          "terms_and_conditions": 'Tagihan bisa dibayar pada tanggal tertentu, jika pembayaran dilakukan pada tanggal tutup maka pembayaran akan dilakukan di hari buka setelahnya'
        },
        "sub_segment": 'GOL 3A',
        'biller_ref': '0000001',
        "bills": [
          {
            "period": '2012-01-01',
            "penalty_fee": '0',
            "amount": '1110',
            "usage": '56',
            "cubication": '402-458',
            'biller_paid_number': 'ABC10001'
          }
        ],
        "response_code": '0000',
        "message": 'successful'
      }
    }.with_indifferent_access
  end

  let(:pending_create_transaction_response) do
    {
      "water_bill_transaction": {
        "customer_number": '19989000000',
        "customer_name": 'JUNAIDI XX001',
        "penalty_fee": '0',
        "currency": 'IDR',
        "total_price": '14110',
        "admin_charge": '1000',
        "start_bill_period": '2012-01-01',
        "end_bill_period": '2012-01-01',
        "usage": '56',
        "address": 'Jalan Ampera Raya No. 22',
        "start_usage_meter": '402',
        "end_usage_meter": '458',
        "reference_number": '12345',
        "operator": {
          "name": 'Denpasar',
          "terms_and_conditions": 'Tagihan bisa dibayar pada tanggal tertentu, jika pembayaran dilakukan pada tanggal tutup maka pembayaran akan dilakukan di hari buka setelahnya'
        },
        "sub_segment": 'GOL 3A',
        'biller_ref': '',
        "bills": [
          {
            "period": '2012-01-01',
            "penalty_fee": '0',
            "amount": '1110',
            "usage": '56',
            "cubication": '402-458',
            'biller_paid_number': ''

          }
        ],
        "response_code": '0063',
        "message": 'no payment'
      }
    }.with_indifferent_access
  end

  let(:failed_create_transaction_response) do
    {
      "water_bill_transaction": {
        "customer_number": '',
        "customer_name": '',
        "penalty_fee": '',
        "currency": 'IDR',
        "total_price": '0',
        "admin_charge": '',
        "start_bill_period": '',
        "end_bill_period": '',
        "usage": '',
        "address": '',
        "start_usage_meter": '',
        "end_usage_meter": '',
        "operator": nil,
        "bills": [],
        "response_code": '0036',
        "message": 'duplicate order id'
      }
    }.with_indifferent_access
  end

  let(:success_get_transaction_response) do
    {
      "water_bill_transaction": {
        "customer_number": '19989000000',
        "customer_name": 'JUNAIDI XX001',
        "penalty_fee": '0',
        "currency": 'IDR',
        "total_price": '14110',
        "admin_charge": '1000',
        "start_bill_period": '2012-01-01',
        "end_bill_period": '2012-01-01',
        "usage": '56',
        "address": 'Jalan Ampera Raya No. 22',
        "start_usage_meter": '402',
        "end_usage_meter": '458',
        "operator": {
          "name": 'Denpasar',
          "terms_and_conditions": 'Tagihan bisa dibayar pada tanggal tertentu, jika pembayaran dilakukan pada tanggal tutup maka pembayaran akan dilakukan di hari buka setelahnya'
        },
        "sub_segment": 'GOL 3A',
        'biller_ref': '0000001',
        "bills": [
          {
            "period": '2012-01-01',
            "penalty_fee": '0',
            "amount": '1110',
            "usage": '56',
            "cubication": '402-458',
            'biller_paid_number': 'ABC10001'
          }
        ],
        "response_code": '0000',
        "message": 'successful'
      }
    }.with_indifferent_access
  end

  let(:pending_get_transaction_response) do
    {
      "water_bill_transaction": {
        "customer_number": '',
        "customer_name": '',
        "penalty_fee": '',
        "currency": 'IDR',
        "total_price": '0',
        "admin_charge": '',
        "start_bill_period": '',
        "end_bill_period": '',
        "usage": '',
        "address": '',
        "start_usage_meter": '',
        "end_usage_meter": '',
        "operator": nil,
        "sub_segment": '',
        'biller_ref': '',
        "bills": [],
        "response_code": '0063',
        "message": 'no payment'
      }
    }.with_indifferent_access
  end

  let(:failed_get_transaction_response) do
    {
      "water_bill_transaction": {
        "customer_number": '',
        "customer_name": '',
        "penalty_fee": '',
        "currency": 'IDR',
        "total_price": '0',
        "admin_charge": '',
        "start_bill_period": '',
        "end_bill_period": '',
        "usage": '',
        "address": '',
        "start_usage_meter": '',
        "end_usage_meter": '',
        "operator": nil,
        "bills": [],
        "response_code": '0092',
        "message": 'order id not found'
      }
    }.with_indifferent_access
  end

  # Electricities Postpaid
  let(:electricity_postpaid_success_inquiry_response) do
    {
      "postpaid_electricity_customer": {
        "customer_name": 'John Doe',
        "customer_number": '512345600003',
        "segmentation": 'R1',
        "power": 1300,
        "stand_meter": '00470300 - 00475700',
        "outstanding_bill": 4,
        "unpaid_bill": 2,
        "period": [
          {},
          {}
        ],
        "penalty_fee": '16000',
        "admin_charge": '2500',
        "bills": [
          {
            "period": {},
            "penalty_fee": '16000',
            "amount": '285305'
          }
        ],
        "currency": 'IDR',
        "total_price": '10000',
        "response_code": '0000',
        "message": 'successful',
        "remaining_billing_sheet": 10
      }
    }.with_indifferent_access
  end

  let(:electricity_postpaid_failed_inquiry_response) do
    {
      "postpaid_electricity_customer": {
        "customer_name": 'John Doe',
        "customer_number": '512345600003',
        "segmentation": '',
        "power": 0,
        "stand_meter": '',
        "outstanding_bill": 0,
        "unpaid_bill": 0,
        "period": [],
        "penalty_fee": '',
        "admin_charge": '',
        "bills": [],
        "currency": 'IDR',
        "total_price": '',
        "response_code": '0014',
        "message": 'unknown number'
      }
    }.with_indifferent_access
  end

  let(:electricity_postpaid_success_inquiry_invalid_bill_response) do
    {
      "postpaid_electricity_customer": {
        "customer_name": 'John Doe',
        "customer_number": '512345600003',
        "segmentation": 'R1',
        "power": 1300,
        "stand_meter": '00470300 - 00475700',
        "outstanding_bill": 4,
        "unpaid_bill": 2,
        "period": [
          {},
          {}
        ],
        "penalty_fee": '16000',
        "admin_charge": '2500',
        "bills": [
          {
            "period": {},
            "penalty_fee": '',
            "amount": ''
          }
        ],
        "currency": 'IDR',
        "total_price": '10000',
        "response_code": '0000',
        "message": 'successful',
        "remaining_billing_sheet": 10
      }
    }.with_indifferent_access
  end

  let(:electricity_postpaid_success_payment_response) do
    {
      "postpaid_electricity_transaction": {
        "order_id": 'order-id-0001',
        "customer_name": 'John Doe',
        "customer_number": '512345600003',
        "segmentation": 'R1',
        "power": 1300,
        "stand_meter": '00470300 - 00475700',
        "outstanding_bill": 4,
        "unpaid_bill": 2,
        "period": [
          {},
          {}
        ],
        "penalty_fee": '16000',
        "admin_charge": '2500',
        "bills": [
          {
            "period": {},
            "penalty_fee": '16000',
            "amount": '285305'
          }
        ],
        "reference_number": '0',
        "info_text": '0',
        "currency": 'IDR',
        "total_price": '10000',
        "response_code": '0000',
        "message": 'successful'
      }
    }.with_indifferent_access
  end

  let(:electricity_postpaid_pending_payment_response) do
    {
      "postpaid_electricity_transaction": {
        "order_id": 'order-id-0001',
        "customer_name": 'John Doe',
        "customer_number": '512345600003',
        "segmentation": 'R1',
        "power": 1300,
        "stand_meter": '00470300 - 00475700',
        "outstanding_bill": 4,
        "unpaid_bill": 2,
        "period": [
          {},
          {}
        ],
        "penalty_fee": '16000',
        "admin_charge": '2500',
        "bills": [
          {
            "period": {},
            "penalty_fee": '16000',
            "amount": '285305'
          }
        ],
        "reference_number": '0',
        "info_text": '0',
        "currency": 'IDR',
        "total_price": '10000',
        "response_code": '0063',
        "message": 'no payment'
      }
    }.with_indifferent_access
  end

  let(:electricity_postpaid_failed_payment_response) do
    {
      "postpaid_electricity_transaction": {
        "order_id": '',
        "customer_name": '',
        "customer_number": '',
        "segmentation": '',
        "power": 0,
        "stand_meter": '',
        "outstanding_bill": 0,
        "unpaid_bill": 0,
        "period": [],
        "penalty_fee": '',
        "admin_charge": '',
        "bills": [],
        "reference_number": '',
        "info_text": '',
        "currency": '',
        "total_price": '',
        "response_code": '0036',
        "message": 'duplicate order id'
      }
    }.with_indifferent_access
  end

  let(:electricity_postpaid_success_get_transaction_response) do
    electricity_postpaid_success_payment_response
  end

  let(:electricity_postpaid_pending_get_transaction_response) do
    electricity_postpaid_pending_payment_response
  end

  let(:electricity_postpaid_failed_get_transaction_response) do
    {
      "postpaid_electricity_transaction": {
        "order_id": '',
        "customer_name": '',
        "customer_number": '',
        "segmentation": '',
        "power": 0,
        "stand_meter": '',
        "outstanding_bill": 0,
        "unpaid_bill": 0,
        "period": [],
        "penalty_fee": '',
        "admin_charge": '',
        "bills": [],
        "reference_number": '',
        "info_text": '',
        "currency": '',
        "total_price": '',
        "response_code": '0092',
        "message": 'order id not found'
      }
    }.with_indifferent_access
  end

  let(:cc_bill_failed_get_transaction_response) do
    {
      "credit_card_bill_transaction": {
        "card_number": '',
        "account_number": '',
        "customer_name": '',
        "statement_date": '',
        "due_date": '',
        "minimum_payment": '',
        "admin_charge": '',
        "amount": '',
        "reference_number": '',
        "financial_journal_number": '',
        "journal_number": '',
        "info": '',
        "response_code": '0092',
        "message":  'order id not found',
        "order_id": ''
      }
    }.with_indifferent_access
  end

  let(:cc_bill_success_payment_response) do
    {
      "credit_card_bill_transaction": {
        "card_number": "5200000099",
        "account_number": "5589871000642902",
        "customer_name": "John Doe",
        "statement_date": "2023-01-01T00:00:00.000Z",
        "due_date": "2023-01-01T00:00:00.000Z",
        "minimum_payment": "50000",
        "admin_charge": "1000",
        "amount": "234000",
        "reference_number": "702209070945101600",
        "financial_journal_number": "24325513",
        "journal_number": "56632111",
        "info": "2023-01-01T00:00:00.000Z",
        "response_code": "0000",
        "message": "Successful",
        "order_id": "order-id-1"
      }
    }.with_indifferent_access
  end

  let(:cc_bill_pending_payment_transaction_response) do
    {
      "credit_card_bill_transaction": {
        "card_number": '',
        "account_number": '',
        "customer_name": '',
        "statement_date": '',
        "due_date": '',
        "minimum_payment": '',
        "admin_charge": '',
        "amount": '',
        "reference_number": '',
        "financial_journal_number": '',
        "journal_number": '',
        "info": '',
        "response_code": '0068',
        "message":  'pending',
        "order_id": ''
      }
    }.with_indifferent_access
  end

  let(:cc_bill_failed_payment_transaction_response) do
    {
      "credit_card_bill_transaction": {
        "card_number": '',
        "account_number": '',
        "customer_name": '',
        "statement_date": '',
        "due_date": '',
        "minimum_payment": '',
        "admin_charge": '',
        "amount": '',
        "reference_number": '',
        "financial_journal_number": '',
        "journal_number": '',
        "info": '',
        "response_code": '0036',
        "message":  'failed',
        "order_id": ''
      }
    }.with_indifferent_access
  end
end
