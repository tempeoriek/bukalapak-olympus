# frozen_string_literal: true

RSpec.shared_context 'tektaya_lets', :shared_context => :metadata do
  let(:valid_single_bill_inquiry_response) do
    {
      'tty': {
        'respcode': '00',
        'mti': '38',
        'kdproduk': '200',
        'userid': 'xx',
        'password': 'xx',
        'bit62': 'xx',
        'sessionkey': 'xx',
        'idpel': '512110000003',
        'trxid': '738263767',
        'message': "| INFORMASI TAGIHAN PLN|| IDPEL : 512110000003| NAMA : DU''MMY-4DEFWWC8WIJH6| TOTAL TAGIHAN : 01 BULAN | BL/TH : MEI21 | RP TAG PLN : Rp. 79.538 | ADMIN BANK : Rp. 0 | TOTAL BAYAR : Rp. 79.538 |",
        'message2': "1|1|01|38B319212DE441B0B1E0000000000000|DU''MMY-4DEFWWC8WIJH6|53211| |I2|000000450|000000000|202105|20052021|00000000|000000079538|C|0000010000|0000000000|000000000000|00008888|00008899|00000000|00000000|00000000|00000000"
      }
    }.with_indifferent_access
  end

  let(:valid_multi_bill_inquiry_response) do
    {
      'tty': {
        'respcode': '00',
        'mti': '38',
        'kdproduk': '200',
        'userid': '',
        'password': '*',
        'bit62': '10190951001000000',
        'sessionkey': 'b20d9b3c5ab714cae47ae5d6380b91fc',
        'idpel': '512510000001',
        'trxid': '738263767',
        'message': "| INFORMASI TAGIHAN PLN|| IDPEL         : 512510000001| NAMA          : DU''MMY-71SUFJPC73K9B| TOTAL TAGIHAN : 05 BULAN | BL/TH         : DES20,JAN21,FEB21,MAR21 | RP TAG PLN    : Rp.        283.940 | ADMIN BANK    : Rp.              0 | TOTAL BAYAR   : Rp.        283.940 |",
        'message2': "4|4|05|E8A41BB694744C808EE0000000000000|DU''MMY-71SUFJPC73K9B|53251|               |R1  |000000450|000000000|202012|20122020|00000000|000000053952|C|0000010000|0000000000|000000009000|00008888|00008899|00000000|00000000|00000000|00000000|202101|20012021|00000000|000000069350|C|0000010000|0000000000|000000009000|00008899|00008910|00000000|00000000|00000000|00000000|202102|20022021|00000000|000000073925|C|0000010000|0000000000|000000009000|00008910|00008921|00000000|00000000|00000000|00000000|202103|20032021|00000000|000000053713|C|0000010000|0000000000|000000006000|00008921|00008932|00000000|00000000|00000000|00000000"
      }
    }.with_indifferent_access
  end

  let(:failed_inquiry_response) do
    {
      'tty': {
        'respcode': '97',
        'mti': '38',
        'kdproduk': '200',
        'userid': 'xx',
        'password': 'xx',
        'bit62': 'xx',
        'sessionkey': 'xx',
        'idpel': '14012909983',
        'trxid': 'EPP443524354',
        'message': 'IDPEL 14012909983 - TRXID EPP443524354 | Cut Off'
      }
    }
  end

  let(:bill_already_paid_inquiry_response) do
    {
      'tty': {
        'respcode': '88',
        'mti': '38',
        'kdproduk': '200',
        'userid': 'xx',
        'password': 'xx',
        'bit62': 'xx',
        'sessionkey': 'xx',
        'idpel': '14012909983',
        'trxid': 'EPP443524354',
        'message': 'Bill Already Paid'
      }
    }
  end

  let(:bill_unavailable_inquiry_response) do
    {
      'tty': {
        'respcode': '89',
        'mti': '38',
        'kdproduk': '200',
        'userid': 'xx',
        'password': 'xx',
        'bit62': 'xx',
        'sessionkey': 'xx',
        'idpel': '545101398421',
        'trxid': 'INQ561078',
        'message': 'IDPEL 545101398421 - TRXID INQ561078 | Tagihan Belum Tersedia'
      }
    }
  end

  let(:bill_exceed_limit_inquiry_response) do
    {
      'tty': {
        'respcode': '17',
        'mti': '38',
        'kdproduk': '200',
        'userid': 'xx',
        'password': 'xx',
        'bit62': 'xx',
        'sessionkey': 'xx',
        'idpel': '14012909983',
        'trxid': 'EPP443524354',
        'message': 'Bill Exceed Limit'
      }
    }
  end

  let(:unregistered_number_inquiry_response) do
    {
      'tty': {
        'respcode': '14',
        'mti': '38',
        'kdproduk': '200',
        'userid': 'xx',
        'password': 'xx',
        'bit62': 'xx',
        'sessionkey': 'xx',
        'idpel': '14012909983',
        'trxid': 'EPP443524354',
        'message': 'Unregistered Number'
      }
    }
  end

  let(:valid_single_bill_create_response) do
    {
      'tty': {
        'respcode': '00',
        'mti': '17',
        'kdproduk': '200',
        'userid': 'xx',
        'password': 'xx',
        'bit62': 'xx',
        'sessionkey': 'xx',
        'idpel': '512110000003',
        'trxid': '738263767',
        'message': "01|1|512110000003|DU''MMY-4DEFWWC8WI|I2|000000450|0|79538|NO REF : 1TKT2121AF1EE8C1354BDBAFD6A0DB5A|~Informasi Hubungi Call Center 123~Atau Hub PLN Terdekat : |MEI21|00008888|00008899|79538|10000|79538"
      }
    }
  end

  let(:valid_multi_bill_create_response) do
    {
      'tty': {
        'respcode': '00',
        'mti': '17',
        'kdproduk': '200',
        'userid': 'xx',
        'password': 'xx',
        'bit62': 'xx',
        'sessionkey': 'xx',
        'idpel': '512510000001',
        'trxid': '738263777',
        'message': "05|4|512510000001|DU''MMY-71SUFJPC73|R1|000000450|0|283940|NO REF : 1TKT21CB63CFCF44D942F2B5B66AC71D|~Informasi Hubungi Call Center 123~Atau Hub PLN Terdekat : |DES20|00008888|00008899|53952|10000|62952|JAN21|00008899|00008910|69350|10000|78350|FEB21|00008910|00008921|73925|10000|82925|MAR21|00008921|00008932|53713|10000|59713"
      }
    }
  end

  let(:failed_create_response) do
    {
      'tty': {
        'respcode': '97',
        'mti': '38',
        'kdproduk': '200',
        'userid': 'xx',
        'password': 'xx',
        'bit62': 'xx',
        'sessionkey': 'xx',
        'idpel': '14012909983',
        'trxid': 'EPP443524354',
        'message': 'IDPEL 14012909983 - TRXID EPP443524354 | Cut Off"'      }
    }
  end

  let(:timeout_create_response) do
    {
      'tty': {
        'respcode': '68',
        'mti': '38',
        'kdproduk': '200',
        'userid': 'xx',
        'password': 'xx',
        'bit62': 'xx',
        'sessionkey': 'xx',
        'idpel': '14012909983',
        'trxid': 'EPP443524354',
        'message': 'TIMEOUT'
      }
    }
  end

  let(:valid_login_response) do
    {
      'tty': {
        'respcode': '00',
        'mti': '58',
        'userid': 'xx',
        'password': 'xx',
        'bit62': 'xx',
        'sessionkey': 'xx'
      }
    }
  end

  let(:invalid_login_response) do
    {
      'tty': {
        'respcode': '97',
        'mti': '58',
        'userid': 'xx',
        'password': 'xx',
        'bit62': 'xx'
      }
    }
  end
end
