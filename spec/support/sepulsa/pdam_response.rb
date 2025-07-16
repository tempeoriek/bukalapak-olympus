RSpec.shared_context "pdam_response", :shared_context => :metadata do
  let(:sepulsa_pdam_single_bill_inquiry_success_response) {
    {
      "admin_charge": "0",
      "pan": "",
      "bills": [
        {
          "waterusage_bill": "",
          "kubikasi": [
            "0-15"
          ],
          "info_text": "",
          "total_usage": "",
          "detail_usage": {
            "usage4": "",
            "usage1": "",
            "usage2": "",
            "usage3": ""
          },
          "bill_amount": [
            "33800"
          ],
          "total_fee": "",
          "bill_date": [
            "202011"
          ],
          "detail_fee": {
            "retribution_fee": "",
            "reconnection_fee": "",
            "service_fee": "",
            "gwt": "",
            "stamp_fee": "",
            "vat": "",
            "nonwater_fee": "",
            "lltt_fee": "",
            "wastewater_fee": "",
            "pdam_fee": "",
            "maintenance_fee": "",
            "installment_amount": "",
            "seal_penalty": ""
          },
          "lift_usage": "",
          "penalty": [
            "0"
          ]
        }
      ],
      "settlement_date": "20201202",
      "local_trx_time": "035225",
      "group_code": "",
      "processing_code": "",
      "bill_repeat_count": "1",
      "acquiring_institution_id": "000",
      "retrieval_ref_no": "1984464798",
      "blth": "202011202011",
      "rp_tag": "33800",
      "trx_id": "",
      "group_desc": "",
      "bill_count": "1",
      "stan": "1984464798",
      "rc": "00",
      "mti": "0210",
      "idpel": "1998900001",
      "response_code": "00",
      "status": true,
      "transmission_datetime": "1606794745",
      "name": "EDOGAWA CONAN SARIFUDIN",
      "local_trx_date": "20201201",
      "customer_address": "",
      "amount": "33800",
      "merchant_code": "6021"
    }
  }

  let(:sepulsa_pdam_single_bill_create_success_response) {
    {
      "token": nil,
      "transaction_id": "171460413",
      "response_code": "10",
      "operator_code": "PDAM KAB. NGAWI",
      "amount": "33800",
      "type": "pdam",
      "changed": "1606769642",
      "customer_number": "1998900001",
      "serial_number": nil,
      "created": "1606769642",
      "price": "35800",
      "status": "pending",
      "data": nil,
      "product_id": {
        "operator": "PDAM KAB. NGAWI",
        "label": "PDAM KAB. NGAWI",
        "enabled": "1",
        "type": "pdam",
        "price": 2000,
        "nominal": "0",
        "product_id": "2989"
      },
      "order_id": "PDM-6140838957"
    }
  }
end
