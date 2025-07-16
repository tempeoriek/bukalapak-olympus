module Channel
  module Ayoconnect
    module Mocks
      module BpjsKetenagakerjaan
        module_function

        def inquiry(payload)
          case payload[:accountNumber]
          when "1871010907918118"
            response_inquiry_bill_already_paid
          when "1871010907918125"
            response_inquiry_account_suspended
          when "1871010907918117"
            response_inquiry_unregistered_number
          when "1871010907918126"
            response_inquiry_partner_issue
          when "1871010907918222"
            response_inquiry_bpu_multi_period(payload[:accountNumber])
          else
            payload[:productCode] == Ayoconnect::BpjsKetenagakerjaan::BPJS_KETENAGAKERJAAN_PRODUCT_CODES[:bpu] ? response_inquiry_bpu(payload[:accountNumber]) : response_inquiry_pu(payload[:accountNumber])
          end
        end

        def response_inquiry_pu(account_number)
          jkp = 0
          firstThreeDigits = account_number[0, 3]
          jkp = 1000 if firstThreeDigits == '200'

          {
            "responseCode": 300,
            "success": true,
            "message": {
              "ID": "Inkuiri berhasil",
              "EN": "Inquiry is successful"
            },
            "data": {
              "inquiryId": 2908677,
              "accountNumber": "#{account_number}",
              "customerName": "JKP EMPAT",
              "productName": "Pembayaran Iuran PU/Jakon",
              "productCode": "TBPJPKPU",
              "category": "BPJS",
              "amount": 111520,
              "totalAdmin": 2500,
              "processingFee": 30,
              "denom": "0",
              "validity": "",
              "customerDetails": [
                {
                  "key": "Nama Perusahaan",
                  "value": "JKP EMPAT"
                },
                {
                  "key": "Kode Iuran",
                  "value": "#{account_number}"
                },
                {
                  "key": "Tanggal & Waktu Pembayaran",
                  "value": "12 Sep 2022 | 10:17"
                }
              ],
              "billDetails": [
                {
                  "billId": "1",
                  "billInfo": [
                    {
                      "key": "Iuran JHT",
                      "value": "63167"
                    },
                    {
                      "key": "Iuran JKK",
                      "value": "17269"
                    },
                    {
                      "key": "Iuran JKM",
                      "value": "3787"
                    },
                    {
                      "key": "Iuran JPK",
                      "value": jkp.to_s
                    },
                    {
                      "key": "Iuran JPN",
                      "value": "24767"
                    }
                  ],
                  "isMandatory": true,
                  "key": "Total Iuran",
                  "value": 108990
                },
                {
                  "billId": "0",
                  "billInfo": [],
                  "isMandatory": true,
                  "key": "Biaya Transaksi",
                  "value": 2500
                }
              ],
              "productDetails": [
                {
                  "key": "NPP",
                  "value": "21000104"
                },
                {
                  "key": "Divisi",
                  "value": "000"
                },
                {
                  "key": "Bulan Tagihan",
                  "value": "09/2021"
                }
              ],
              "extraFields": []
            }
          }.with_indifferent_access
        end

        def response_inquiry_bpu(account_number)
          {
            "responseCode": 300,
            "success": true,
            "message": {
              "ID": "Inkuiri berhasil",
              "EN": "Inquiry is successful"
            },
            "data": {
              "inquiryId": 2908621,
              "accountNumber": "#{account_number}",
              "customerName": "NICO JULIAN",
              "productName": "Pembayaran Iuran BPU/PMI",
              "productCode": "TBPJPKBU",
              "category": "BPJS",
              "amount": 36800,
              "totalAdmin": 0,
              "processingFee": 0,
              "denom": "0",
              "validity": "",
              "customerDetails": [
                {
                  "key": "Nama",
                  "value": "NICO JULIAN"
                },
                {
                  "key": "NIK / ID Billing",
                  "value": "#{account_number}"
                },
                {
                  "key": "Tanggal & Waktu Pembayaran",
                  "value": "10:13 | 12 Sep 2022"
                }
              ],
              "billDetails": [
                {
                  "billId": "1",
                  "billInfo": [
                    {
                      "key": "Iuran JHT",
                      "value": "20000"
                    },
                    {
                      "key": "Iuran JKK",
                      "value": "10000"
                    },
                    {
                      "key": "Iuran JKM",
                      "value": "6800"
                    }
                  ],
                  "isMandatory": true,
                  "key": "Total Iuran",
                  "value": 36800
                },
                {
                  "billId": "0",
                  "billInfo": [],
                  "isMandatory": true,
                  "key": "Biaya Transaksi",
                  "value": 0
                }
              ],
              "productDetails": [
                {
                  "key": "Tanggal Efektif Masa Perlindungan",
                  "value": "27-08-2021 "
                },
                {
                  "key": "Tanggal Berakhir Masa Perlindungan",
                  "value": "26-09-2021 "
                },
                {
                  "key": "Kantor Cabang",
                  "value": "JAKARTA GROGOL"
                },
                {
                  "key": "Kode Iuran",
                  "value": "921083112662"
                }
              ],
              "extraFields": [
                {
                  "key": "Tunggakan",
                  "value": ""
                }
              ]
            }
          }.with_indifferent_access
        end

        def response_inquiry_bpu_multi_period(account_number)
          response = response_inquiry_bpu(account_number)
          response[:data][:productDetails] = [
            {
              "key": "Tanggal Efektif Masa Perlindungan",
              "value": "27-08-2021 "
            },
            {
              "key": "Tanggal Berakhir Masa Perlindungan",
              "value": "26-10-2021 "
            },
            {
              "key": "Kantor Cabang",
              "value": "JAKARTA GROGOL"
            },
            {
              "key": "Kode Iuran",
              "value": "921083112662"
            }
          ]
          response[:data][:billDetails] = [
            {
              "billId": "2",
              "billInfo": [
                {
                  "key": "Iuran JHT",
                  "value": "10000"
                },
                {
                  "key": "Iuran JKK",
                  "value": "15000"
                },
                {
                  "key": "Iuran JKM",
                  "value": "5000"
                }
              ],
              "isMandatory": true,
              "key": "Total Iuran",
              "value": 30000
            },
            {
              "billId": "1",
              "billInfo": [
                {
                  "key": "Iuran JHT",
                  "value": "20000"
                },
                {
                  "key": "Iuran JKK",
                  "value": "10000"
                },
                {
                  "key": "Iuran JKM",
                  "value": "6800"
                }
              ],
              "isMandatory": true,
              "key": "Total Iuran",
              "value": 36800
            },
            {
              "billId": "0",
              "billInfo": [],
              "isMandatory": true,
              "key": "Biaya Transaksi",
              "value": 0
            }
          ]
          response
        end

        # Inquiry - bill already paid - 18118
        def response_inquiry_bill_already_paid
          {
            "responseCode": 302,
            "success": false,
            "message": {
              "ID": "inquiry Failed, Bill Already Paid",
              "EN": "inquiry Failed, Bill Already Paid"
            },
            "data": {}
          }.with_indifferent_access
        end

        # Inquiry - blocked IDPEL - AccountSuspended - 12125
        def response_inquiry_account_suspended
          {
            "responseCode": 112,
            "success": false,
            "message": {
              "ID": "Block IDPEL",
              "EN": "Block IDPEL"
            },
            "data": {}
          }.with_indifferent_access
        end

        # Inquiry - blocked IDPEL - UnregisteredNumber - 18117
        def response_inquiry_unregistered_number
          {
            "responseCode": 304,
            "success": false,
            "message": {
              "ID": "Check your number and try again",
              "EN": "Check your number and try again"
            },
            "data": {}
          }.with_indifferent_access
        end

        # Inquiry - PartnerIssue
        def response_inquiry_partner_issue
          {
            "responseCode": 184,
            "success": false,
            "message": {
              "ID": "Partner Issue",
              "EN": "Partner Issue"
            },
            "data": {}
          }.with_indifferent_access
        end

        # confirm transaction
        def check_status(payload)
          remote_transaction_id = payload[:refNumber].split('-')[1]

          trx = ::BpjsKetenagakerjaanTransaction.find_by(remote_transaction_id: remote_transaction_id)
          return response_not_found unless trx.present?

          failed_and_processing_create_response = ['199', '299']
          lastThreeDigits = trx.customer_number[-3, 3]
          raise ::Exceptions::PartnerTransactionNotFound if failed_and_processing_create_response.include? lastThreeDigits

          trx.bpjs_tk_type == 'bpu' ? check_status_bpu(trx.customer_number) : check_status_pu(trx.customer_number)
        end

        def response_not_found
          {
            "responseCode": 188,
            "success": false,
            "message": {
              "ID": "transaksi tidak tersedia",
              "EN": "transaction is not available"
            },
            "data": {
              "refNumber": "",
              "transactionId": 0,
              "accountNumber": "",
              "amount": 0,
              "totalAdmin": 0,
              "processingFee": 0,
              "denom": "",
              "productCode": "",
              "productName": "",
              "category": "",
              "token": "",
              "customerDetails": nil,
              "billDetails": nil,
              "productDetails": nil,
              "extraFields": nil
            }
          }.with_indifferent_access
        end

        def check_status_bpu(account_number)
          {
            "responseCode": 0,
            "success": true,
            "message": {
              "ID": "Transaksi Anda Telah Berhasil",
              "EN": "Your transaction was successful"
            },
            "status": 2,
            "customer_number": "#{account_number}",
            "partner_transaction_id": 184699,
            "data": {
              "refNumber": "bceue8hece83",
              "transactionId": 184699,
              "accountNumber": "#{account_number}",
              "amount": 36800,
              "totalAdmin": 0,
              "processingFee": 0,
              "denom": "0",
              "productCode": "TBPJPKBU",
              "productName": "Pembayaran Iuran BPU/PMI",
              "category": "BPJS",
              "token": "JHT166295238991653#JKK166295238991653#JKM166295238991653",
              "customerDetails": [
                {
                  "key": "Tanggal & Waktu Pembayaran",
                  "value": "12 Sep 2022 | 10:14"
                },
                {
                  "key": "Nama",
                  "value": "NICO JULIAN"
                },
                {
                  "key": "NIK / ID Billing",
                  "value": "#{account_number}"
                }
              ],
              "billDetails": [
                {
                  "billId": "1",
                  "billInfo": [
                    {
                      "key": "Iuran JHT",
                      "value": "20000"
                    },
                    {
                      "key": "Iuran JKK",
                      "value": "10000"
                    },
                    {
                      "key": "Iuran JKM",
                      "value": "6800"
                    }
                  ],
                  "key": "Total Iuran",
                  "value": "36800"
                },
                {
                  "billId": "0",
                  "billInfo": [],
                  "key": "Biaya Transaksi",
                  "value": "0"
                }
              ],
              "productDetails": [
                {
                  "key": "Tanggal Efektif Masa Perlindungan",
                  "value": "27-08-2021 "
                },
                {
                  "key": "Tanggal Berakhir Masa Perlindungan",
                  "value": "26-09-2021 "
                },
                {
                  "key": "Kantor Cabang",
                  "value": "JAKARTA GROGOL"
                },
                {
                  "key": "Nomor Kepesertaan",
                  "value": "-"
                },
                {
                  "key": "Nomor Referensi",
                  "value": "AYO166295238991653"
                },
                {
                  "key": "Kode Iuran",
                  "value": "921083112662"
                }
              ],
              "extraFields": []
            }
          }.with_indifferent_access
        end

        def check_status_pu(account_number)
          {
            "responseCode": 0,
            "success": true,
            "message": {
              "ID": "Transaksi Anda Telah Berhasil",
              "EN": "Your transaction was successful"
            },
            "status": 2,
            "customer_number": "#{account_number}",
            "partner_transaction_id": 184700,
            "data": {
              "refNumber": "jfiejfejcefji4",
              "transactionId": 184700,
              "accountNumber": "#{account_number}",
              "amount": 111490,
              "totalAdmin": 2500,
              "processingFee": 0,
              "denom": "0",
              "productCode": "TBPJPKPU",
              "productName": "Pembayaran Iuran PU/Jakon",
              "category": "BPJS",
              "token": "JHT166295262365619#JKK166295262365619#JKM166295262365619#JPN166295262365619",
              "customerDetails": [
                {
                  "key": "Tanggal & Waktu Pembayaran",
                  "value": "12 Sep 2022 | 10:18"
                },
                {
                  "key": "Nama Perusahaan",
                  "value": "JKP EMPAT"
                },
                {
                  "key": "Kode Iuran",
                  "value": "#{account_number}"
                }
              ],
              "billDetails": [
                {
                  "billId": "1",
                  "billInfo": [
                    {
                      "key": "Iuran JHT",
                      "value": "63167"
                    },
                    {
                      "key": "Iuran JKK",
                      "value": "17269"
                    },
                    {
                      "key": "Iuran JKM",
                      "value": "3787"
                    },
                    {
                      "key": "Iuran JPK",
                      "value": "0"
                    },
                    {
                      "key": "Iuran JPN",
                      "value": "24767"
                    }
                  ],
                  "key": "Total Iuran",
                  "value": "108990"
                },
                {
                  "billId": "0",
                  "billInfo": [],
                  "key": "Biaya Transaksi",
                  "value": "2500"
                }
              ],
              "productDetails": [
                {
                  "key": "NPP",
                  "value": "21000104"
                },
                {
                  "key": "Divisi",
                  "value": "000"
                },
                {
                  "key": "Bulan Tagihan",
                  "value": "09/2021"
                },
                {
                  "key": "Nomor Referensi",
                  "value": "AYO166295262365619"
                }
              ],
              "extraFields": []
            }
          }.with_indifferent_access
        end

        # create transaction
        def create(payload)
          lastThreeDigits = payload[:accountNumber][-3, 3]

          case lastThreeDigits
          when "299"
            create_response_processing(payload)
          when "199"
            create_response_failed(payload)
          else
            create_response_success(payload)
          end
        end

        # Create - partner status is success
        def create_response_success(payload)
          payload[:productCode] == Ayoconnect::BpjsKetenagakerjaan::BPJS_KETENAGAKERJAAN_PRODUCT_CODES[:bpu]? check_status_bpu(payload[:account_number]) : check_status_pu(payload[:account_number])
        end

        # Create - partner status is processing
        def create_response_processing(payload)
          response = payload[:productCode] == Ayoconnect::BpjsKetenagakerjaan::BPJS_KETENAGAKERJAAN_PRODUCT_CODES[:bpu]? check_status_bpu(payload[:account_number]) : check_status_pu(payload[:account_number])
          response[:status] = 0
          response
        end

        # Create - partner status is failed
        def create_response_failed(payload)
          response = payload[:productCode] == Ayoconnect::BpjsKetenagakerjaan::BPJS_KETENAGAKERJAAN_PRODUCT_CODES[:bpu]? check_status_bpu(payload[:account_number]) : check_status_pu(payload[:account_number])
          response[:status] = 3
          response
        end
      end
    end
  end
end
