module Channel
  module Thor
    module Mocks
      module Pdam
        module_function

        def inquiry
          {
            "customer_number": "19989000068",
            "customer_name": "JUNAIDI XX001",
            "penalty_fee": "0",
            "currency": "IDR",
            "total_price": "14110",
            "admin_charge": "1000",
            "start_bill_period": "2012-01-01",
            "end_bill_period": "2012-01-01",
            "usage": "56",
            "address": "Jalan Ampera Raya No. 22",
            "start_usage_meter": "402",
            "end_usage_meter": "458",
            "stand_meter": "123456",
            "segel": "1000",
            "retribution": "1500",
            "operator": {
              "name": "Denpasar",
              "terms_and_conditions": "Tagihan bisa dibayar pada tanggal tertentu, jika pembayaran dilakukan pada tanggal tutup maka pembayaran akan dilakukan di hari buka setelahnya"
            },
            "bills": [
              {
                "period": "2012-01-01",
                "penalty_fee": "0",
                "amount": "1110",
                "usage": "56",
                "cubication": "402-458",
                "stamp_duty": "3000",
                "retribution": "1000"
              },
              {
                "period": "2012-02-01",
                "penalty_fee": "0",
                "amount": "1110",
                "usage": "56",
                "cubication": "458-600",
                "stamp_duty": "4000",
                "retribution": "2000"
              }
            ],
            "response_code": "0000",
            "message": "successful"
          }.with_indifferent_access
        end
      end
    end
  end
end
