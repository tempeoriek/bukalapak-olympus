RSpec.shared_context "ayoconnect_lets", :shared_context => :metadata do
  let(:valid_inquiry_response) do
    {
      "responseCode": 300,
      "success": true,
      "message": {
        "ID": "Inkuiri berhasil",
        "EN": "Inquiry is successful"
      },
      "data": {
        "inquiryId": 2294793,
        "accountNumber": "516070377764",
        "customerName": "JOENET LEMBAYUNG",
        "productName": "PLN Postpaid",
        "productCode": "LSTPPPOG",
        "category": "Listrik",
        "amount": 101539,
        "totalAdmin": 6000,
        "processingFee": 0,
        "denom": "",
        "validity": "",
        "customerDetails": [
          {
            "key": "Nama Pelanggan",
            "value": "JOENET LEMBAYUNG"
          },
          {
            "key": "Tanggal & Waktu Pembayaran",
            "value": "09 Dec 2021 | 14:21"
          },
          {
            "key": "Nomor Pelanggan",
            "value": "516070377764"
          }
        ],
        "billDetails": [
          {
            "billId": "1",
            "billInfo": [
              {
                "key": "Rp Tag PLN",
                "value": "32661"
              },
              {
                "key": "Denda",
                "value": "6000"
              },
              {
                "key": "Jatuh Tempo",
                "value": "20-Feb-2016"
              },
              {
                "key": "Insentif",
                "value": "D0000000000"
              },
              {
                "key": "Pemakaian",
                "value": "8200 kWh"
              },
              {
                "key": "Stand Meter",
                "value": "1076100-1084300"
              },
              {
                "key": "Bulan",
                "value": "Jan 2016"
              }
            ],
            "isMandatory": true,
            "key": "Jumlah Tagihan",
            "value": 38661
          },
          {
            "billId": "2",
            "billInfo": [
              {
                "key": "Rp Tag PLN",
                "value": "43878"
              },
              {
                "key": "Denda",
                "value": "3000"
              },
              {
                "key": "Jatuh Tempo",
                "value": "20-Mar-2016"
              },
              {
                "key": "Insentif",
                "value": "D0000000000"
              },
              {
                "key": "Pemakaian",
                "value": "10400 kWh"
              },
              {
                "key": "Stand Meter",
                "value": "1084300-1094700"
              },
              {
                "key": "Bulan",
                "value": "Feb 2016"
              }
            ],
            "isMandatory": true,
            "key": "Jumlah Tagihan",
            "value": 46878
          },
          {
            "billId": "3",
            "billInfo": [
              {
                "key": "Rp Tag PLN",
                "value": "7000"
              },
              {
                "key": "Denda",
                "value": "3000"
              },
              {
                "key": "Jatuh Tempo",
                "value": "20-Apr-2016"
              },
              {
                "key": "Insentif",
                "value": "D0000000000"
              },
              {
                "key": "Pemakaian",
                "value": "17600 kWh"
              },
              {
                "key": "Stand Meter",
                "value": "1094700-1112300"
              },
              {
                "key": "Bulan",
                "value": "Mar 2016"
              }
            ],
            "isMandatory": true,
            "key": "Jumlah Tagihan",
            "value": 10000
          },
          {
            "billId": "0",
            "billInfo": [],
            "isMandatory": true,
            "key": "Biaya Administrasi",
            "value": 6000
          }
        ],
        "productDetails": [
          {
            "key": "BL/TH",
            "value": "Jan 2016, Feb 2016, Mar 2016"
          },
          {
            "key": "Total LBR Tagihan",
            "value": "3 Bulan"
          },
          {
            "key": "Total Tarif/Daya",
            "value": "A1/000000550"
          },
          {
            "key": "Total Pemakaian",
            "value": "36200 kWh"
          },
          {
            "key": "Stand Meter",
            "value": "1076100-1084300, 1084300-1094700, 1094700-1112300"
          }
        ],
        "extraFields": []
      }
    }.with_indifferent_access
  end

  let(:valid_bpjs_ketenagakerjaan_pu_inquiry_response) do
    {
      "responseCode": 300,
      "success": true,
      "message": {
        "ID": "Inkuiri berhasil",
        "EN": "Inquiry is successful"
      },
      "data": {
        "inquiryId": 2908677,
        "accountNumber": "210800004501",
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
            "value": "210800004501"
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
                "value": "0"
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

  let(:valid_bpjs_ketenagakerjaan_bpu_inquiry_response) do
    {
      "responseCode": 300,
      "success": true,
      "message": {
        "ID": "Inkuiri berhasil",
        "EN": "Inquiry is successful"
      },
      "data": {
        "inquiryId": 2908621,
        "accountNumber": "1871010907930009",
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
            "value": "187101090793000901"
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
            "value": "N/A"
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

  let(:valid_bpjs_ketenagakerjaan_bpu_inquiry_response_with_tunggakan) do
    response = valid_bpjs_ketenagakerjaan_bpu_inquiry_response
    response[:data][:productDetails].each do |attr|
      if attr[:key] == 'Kode Iuran'
        attr[:value] = '921083112662'
      end
    end

    response[:data][:extraFields].each do |attr|
      if attr[:key] == 'Tunggakan'
        attr[:value] = 'Total Iuran diatas merupakan nominal dari kode iuran yang belum terbayarkan sebelumnya.'
      end
    end

    response
  end

  let(:failed_inquiry_response) do
    {
      "responseCode": 304,
      "success": false,
      "message": {
        "ID": "Inquiry is failed",
        "EN": "Inquiry is failed"
      },
      "data": {}
    }
  end

  let(:failed_partner_inquiry_response) do
    {
      "responseCode": 313,
      "success": false,
      "message": {
        "ID": "Inquiry is failed",
        "EN": "Inquiry is failed"
      },
      "data": {}
    }
  end

  let(:empty_inquiry_response_code) do
    {
      "success": false,
      "message": {
        "ID": "Inquiry is failed",
        "EN": "Inquiry is failed"
      },
      "data": {}
    }
  end

  let(:check_status_success_response) do
    {
      "responseCode": 0,
      "success": true,
      "message": {
        "ID": "Transaksi Anda Telah Berhasil",
        "EN": "Your transaction was successful"
      },
      "data": {
        "refNumber": "test-002",
        "transactionId": 141793,
        "accountNumber": "516070377764",
        "amount": 101539,
        "totalAdmin": 6000,
        "processingFee": 0,
        "denom": "",
        "productCode": "LSTPPPOG",
        "productName": "PLN Postpaid",
        "category": "Listrik",
        "token": "0MUP210Z3293B8A45CEE7CE3CE77D3CC",
        "customerDetails": [
          {
            "key": "Nama Pelanggan",
            "value": "JOENET LEMBAYUNG"
          },
          {
            "key": "Tanggal & Waktu Pembayaran",
            "value": "09 Dec 2021 | 16:18"
          },
          {
            "key": "Nomor Pelanggan",
            "value": "516070377764"
          }
        ],
        "billDetails": [
          {
            "billId": "1",
            "billInfo": [
              {
                "key": "Rp Tag PLN",
                "value": "32661"
              },
              {
                "key": "Denda",
                "value": "6000"
              },
              {
                "key": "Jatuh Tempo",
                "value": "20-Feb-2016"
              },
              {
                "key": "Insentif",
                "value": "D0000000000"
              },
              {
                "key": "Pemakaian",
                "value": "8200 kWh"
              },
              {
                "key": "Stand Meter",
                "value": "1076100-1084300"
              },
              {
                "key": "Bulan",
                "value": "Jan 2016"
              }
            ],
            "key": "Jumlah Tagihan",
            "value": 38661
          },
          {
            "billId": "2",
            "billInfo": [
              {
                "key": "Rp Tag PLN",
                "value": "43878"
              },
              {
                "key": "Denda",
                "value": "3000"
              },
              {
                "key": "Jatuh Tempo",
                "value": "20-Mar-2016"
              },
              {
                "key": "Insentif",
                "value": "D0000000000"
              },
              {
                "key": "Pemakaian",
                "value": "10400 kWh"
              },
              {
                "key": "Stand Meter",
                "value": "1084300-1094700"
              },
              {
                "key": "Bulan",
                "value": "Feb 2016"
              }
            ],
            "key": "Jumlah Tagihan",
            "value": 46878
          },
          {
            "billId": "3",
            "billInfo": [
              {
                "key": "Rp Tag PLN",
                "value": "7000"
              },
              {
                "key": "Denda",
                "value": "3000"
              },
              {
                "key": "Jatuh Tempo",
                "value": "20-Apr-2016"
              },
              {
                "key": "Insentif",
                "value": "D0000000000"
              },
              {
                "key": "Pemakaian",
                "value": "17600 kWh"
              },
              {
                "key": "Stand Meter",
                "value": "1094700-1112300"
              },
              {
                "key": "Bulan",
                "value": "Mar 2016"
              }
            ],
            "key": "Jumlah Tagihan",
            "value": 10000
          },
          {
            "billId": "0",
            "billInfo": [],
            "key": "Biaya Administrasi",
            "value": 6000
          }
        ],
        "productDetails": [
          {
            "key": "BL/TH",
            "value": "Jan 2016, Feb 2016, Mar 2016"
          },
          {
            "key": "Total LBR Tagihan",
            "value": "3 Bulan"
          },
          {
            "key": "Total Tarif/Daya",
            "value": "A1/000000550"
          },
          {
            "key": "Stand Meter",
            "value": "1076100-1084300, 1084300-1094700, 1094700-1112300"
          },
          {
            "key": "Total Pemakaian",
            "value": "36200 kWh"
          },
          {
            "key": "Nomor Referensi",
            "value": "0MUP210Z3293B8A45CEE7CE3CE77D3CC"
          }
        ],
        "extraFields": []
      }
    }
  end

  let(:check_status_fail_response) do
    {
      "responseCode": 103,
      "success": false,
      "message": {
        "ID": "Transaksi Gagal, Nomor yang Anda Masukkan Salah/Expired",
        "EN": "Your transaction failed, wrong number"
      },
      "data": {
        "refNumber": "test-002",
        "transactionId": 141901,
        "accountNumber": "516070377764",
        "amount": 101539,
        "totalAdmin": 6000,
        "processingFee": 0,
        "denom": "",
        "productCode": "LSTPPPOG",
        "productName": "PLN Postpaid",
        "category": "Listrik",
        "token": "N/A",
        "customerDetails": [],
        "billDetails": [],
        "productDetails": [],
        "extraFields": []
      }
    }
  end

  let(:check_status_pending_response) do
    {
      "responseCode": 299,
      "success": true,
      "message": {
        "ID": "Transaksi Anda Sedang Diproses",
        "EN": "Your transaction was being processed"
      },
      "data": {
        "refNumber": "test-002",
        "transactionId": 141793,
        "accountNumber": "516070377764",
        "amount": 101539,
        "totalAdmin": 6000,
        "processingFee": 0,
        "denom": "",
        "productCode": "LSTPPPOG",
        "productName": "PLN Postpaid",
        "category": "Listrik",
        "token": "N/A",
        "customerDetails": [],
        "billDetails": [],
        "productDetails": [],
        "extraFields": []
      }
    }
  end

  let(:unavailable_check_trx_response) do
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
    }
  end

  let(:valid_create_response) do
    {
      "responseCode": 299,
      "success": true,
      "message": {
        "ID": "Transaksi sedang dalam proses",
        "EN": "Your transaction is being processed"
      },
      "data": {
        "refNumber": "test-002",
        "transactionId": 141793,
        "accountNumber": "516070377764",
        "amount": 101539,
        "totalAdmin": 6000,
        "processingFee": 0,
        "denom": "",
        "productCode": "LSTPPPOG",
        "productName": "PLN Postpaid",
        "category": "Listrik",
        "token": "N/A",
        "customerDetails": [],
        "billDetails": [],
        "productDetails": [],
        "extraFields": []
      }
    }
  end

  let(:failed_create_response) do
    {
      "responseCode": 100,
      "success": false,
      "message": {
        "ID": "Transaksi Gagal, Gangguan Operator",
        "EN": "Transaction Failed, Operator Issue"
      },
      "data": {}
    }
  end

  # BPJS Ketenagakerjaan

  let(:check_status_success_response_bjps_tk_pu) do
    {
      "responseCode": 0,
      "success": true,
      "message": {
        "ID": "Transaksi Anda Telah Berhasil",
        "EN": "Your transaction was successful"
      },
      "data": {
        "refNumber": "jfiejfejcefji4",
        "transactionId": 184700,
        "accountNumber": "210800004501",
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
            "value": "210800004501"
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

  let(:check_status_success_response_bjps_tk_bpu) do
    {
      "responseCode": 0,
      "success": true,
      "message": {
        "ID": "Transaksi Anda Telah Berhasil",
        "EN": "Your transaction was successful"
      },
      "data": {
        "refNumber": "bceue8hece83",
        "transactionId": 184699,
        "accountNumber": "187101090793000901",
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
            "value": "187101090793000901"
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

  let(:check_status_failed_response_bjps_tk) do
    {
      "responseCode": 103,
      "success": false,
      "message": {
        "ID": "Transaksi Gagal, Nomor yang Anda Masukkan Salah/Expired",
        "EN": "Your transaction failed, wrong number"
      },
      "data": {
        "refNumber": "bceue8hece83",
        "transactionId": 0,
        "accountNumber": "187101090793000901",
        "amount": 0,
        "totalAdmin": 0,
        "processingFee": 0,
        "denom": "0",
        "productCode": "TBPJPKBU",
        "productName": "Pembayaran Iuran BPU/PMI",
        "category": "BPJS",
        "token": "N/A",
        "customerDetails": [],
        "billDetails": [],
        "productDetails": [],
        "extraFields": []
      }
    }.with_indifferent_access
  end

  let(:check_status_in_process_response_bjps_tk) do
    {
      "responseCode": 299,
      "success": false,
      "message": {
        "ID": "Transaksi Anda Sedang Diproses",
        "EN": "Your transaction was being processed"
      },
      "data": {
        "refNumber": "bceue8hece83",
        "transactionId": 0,
        "accountNumber": "187101090793000901",
        "amount": 0,
        "totalAdmin": 0,
        "processingFee": 0,
        "denom": "0",
        "productCode": "TBPJPKBU",
        "productName": "Pembayaran Iuran BPU/PMI",
        "category": "BPJS",
        "token": "N/A",
        "customerDetails": [],
        "billDetails": [],
        "productDetails": [],
        "extraFields": []
      }
    }.with_indifferent_access
  end

  let(:valid_create_response_bpjs_tk_bpu) { check_status_success_response_bjps_tk_bpu }

  let(:valid_create_response_bpjs_tk_pu) { check_status_success_response_bjps_tk_pu }

  let(:pending_create_response_bpjs_tk) { check_status_in_process_response_bjps_tk }

  let(:valid_inquiry_response_new_format) do
    {
      "responseCode": 300,
      "success": true,
      "message": {
        "ID": "Inkuiri berhasil",
        "EN": "Inquiry is successful"
      },
      "data": {
        "inquiryId": 2294793,
        "accountNumber": "516070377764",
        "customerName": "JOENET LEMBAYUNG",
        "productName": "PLN Postpaid",
        "productCode": "LSTPPPOG",
        "category": "Listrik",
        "amount": 101539,
        "totalAdmin": 6000,
        "processingFee": 0,
        "denom": "",
        "validity": "",
        "customerDetails": [
          {
            "key": "Nama Pelanggan",
            "value": "JOENET LEMBAYUNG"
          },
          {
            "key": "Tanggal & Waktu Pembayaran",
            "value": "09 Dec 2021 | 14:21"
          },
          {
            "key": "Nomor Pelanggan",
            "value": "516070377764"
          }
        ],
        "billDetails": [
          {
            "billId": "1",
            "billInfo": [
              {
                "key": "Rp Tag PLN",
                "value": "32661"
              },
              {
                "key": "Denda",
                "value": "6000"
              },
              {
                "key": "Jatuh Tempo",
                "value": "20-Feb-2016"
              },
              {
                "key": "Insentif",
                "value": "D0000000000"
              },
              {
                "key": "Pemakaian",
                "value": "8200 kWh"
              },
              {
                "key": "Stand Meter",
                "value": "1076100-1084300"
              },
              {
                "key": "Bulan",
                "value": "Jan24"
              }
            ],
            "isMandatory": true,
            "key": "Jumlah Tagihan",
            "value": 38661
          },
          {
            "billId": "2",
            "billInfo": [
              {
                "key": "Rp Tag PLN",
                "value": "43878"
              },
              {
                "key": "Denda",
                "value": "3000"
              },
              {
                "key": "Jatuh Tempo",
                "value": "20-Mar-2016"
              },
              {
                "key": "Insentif",
                "value": "D0000000000"
              },
              {
                "key": "Pemakaian",
                "value": "10400 kWh"
              },
              {
                "key": "Stand Meter",
                "value": "1084300-1094700"
              },
              {
                "key": "Bulan",
                "value": "Feb24"
              }
            ],
            "isMandatory": true,
            "key": "Jumlah Tagihan",
            "value": 46878
          },
          {
            "billId": "3",
            "billInfo": [
              {
                "key": "Rp Tag PLN",
                "value": "7000"
              },
              {
                "key": "Denda",
                "value": "3000"
              },
              {
                "key": "Jatuh Tempo",
                "value": "20-Apr-2016"
              },
              {
                "key": "Insentif",
                "value": "D0000000000"
              },
              {
                "key": "Pemakaian",
                "value": "17600 kWh"
              },
              {
                "key": "Stand Meter",
                "value": "1094700-1112300"
              },
              {
                "key": "Bulan",
                "value": "Mar24"
              }
            ],
            "isMandatory": true,
            "key": "Jumlah Tagihan",
            "value": 10000
          },
          {
            "billId": "0",
            "billInfo": [],
            "isMandatory": true,
            "key": "Biaya Administrasi",
            "value": 6000
          }
        ],
        "productDetails": [
          {
            "key": "BL/TH",
            "value": "Jan 2016, Feb 2016, Mar 2016"
          },
          {
            "key": "Total LBR Tagihan",
            "value": "3 Bulan"
          },
          {
            "key": "Total Tarif/Daya",
            "value": "R1M/000000900VA"
          },
          {
            "key": "Total Pemakaian",
            "value": "36200 kWh"
          },
          {
            "key": "Stand Meter",
            "value": "1076100-1084300, 1084300-1094700, 1094700-1112300"
          }
        ],
        "extraFields": []
      }
    }.with_indifferent_access
  end
end
