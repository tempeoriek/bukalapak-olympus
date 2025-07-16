RSpec.shared_context 'electricity_mocks',
:shared_context => :metadata do
  include Postpaid::Constant

  let(:electricity_transaction) { build(:postpaid_transaction_with_bill, :processed) }
  let(:success_response) {
    ResponseGeneralizer::ElectricityPostpaid.new({}, electricity_transaction.partner_object) do |r|
      r.status = SUCCESS
      r.reference_number = 'ABC123'
      r.partner_transaction_id = 1
      r.stand_meter = "00047824-000048084"
      r.segmentation = "R1M"
      r.power = "900"
    end
  }
  let(:failed_response) {
    ResponseGeneralizer::ElectricityPostpaid.new({}, electricity_transaction.partner_object) do |r|
      r.status = FAILED
      r.message = "Transaksi gagal"
    end
  }
  let(:pending_response) {
    ResponseGeneralizer::ElectricityPostpaid.new({}, electricity_transaction.partner_object) do |r|
      r.status = PENDING
    end
  }

  ## BUKOPIN DIRECT ##
  let(:stan) { 65 }
  let(:customer_number) { '530000000001' }

  let(:bukopin_token) { '91e385d46d9756b5' }

  let(:bukopin_network_iso_response) { '281000100000838100002020010815162707441126000001010000000BUKALAPAK048645F0C7B1F8C3192C9A6DC3F002F779C29F2F423646D0A82' }
  let(:bukopin_network_request_response) {
    {12=>Time.now, 39=>"0000", 40=>101, 41=>"0000000BUKALAPAK", 48=>"42BEFFD4F48E777E420FAF5531FE4696D526747087488650"}
  }

  let(:bukopin_inquiry_iso_response) { '211050300041828100000599501360000000030000000000000000620200107091450602107441001007441126000000000000BUKALAPAK23600000005300000000011018F21B5F4A5FFBE5E0B2C52E2F088BA06SUBCRIBER NAME           00005000000000000015  R10000013000000000002020010701202007012020000000300000C00000000000000000000000000000000000011110000222200000008000000080000000800000008' }
  let(:bukopin_failed_inquiry_iso_response) { '211050300041828100000599501360000000000000000000000000720200107092044602107441001007441126000160000000BUKALAPAK0280000000520000000016000000000","response":{"status":"failed","response_code":"0016","message":"Konsumen 520000000016 diblokir. Hubungi PLN.' }
  let(:bukopin_inquiry_reference_number) { '044121CB5FF14476B83195DB922B05EB' }
  let(:bukopin_inquiry_request_response) {{
    :status=>"success",
    :response_code=>"0000",
    :customer_number=>"530000000001",
    :customer_name=>"SUBCRIBER NAME           ",
    :segmentation=>"  R1",
    :power=>1300,
    :stand_meter=>"00001111 - 00002222",
    :outstanding_bill=>1,
    :unpaid_bill=>0,
    :admin_charge=>0,
    :amount=>300000,
    :reference_number=>"#{bukopin_inquiry_reference_number}",
    :bills=>[{:bill_period=>"202001",
      :due_date=>"07012020",
      :meter_read_date=>"07012020",
      :total_electricity_bill=>"000000300000",
      :incentive=>"C0000000000",
      :value_added_tax=>"0000000000",
      :penalty_fee=>0,
      :previous_meter_reading=>"00001111",
      :current_meter_reading=>"00002222",
      :previous_meter_reading_2=>"00000008",
      :current_meter_reading_2=>"00000008",
      :previous_meter_reading_3=>"00000008",
      :current_meter_reading_3=>"00000008",
      :amount=>300000,
      :previous_meter=>"00001111",
      :current_meter=>"00002222"}],
      :bill_status=>"1",
      :info_text=>"RINCIAN TAGIHAN DAPAT DIAKSES DI \"www.pln.co.id\" ATAU PLN TERDEKAT. Powered by Bukopinet.",
      :stan=>6,
      :raw_data=>{
        12=>"2020-01-07T09:15:11.000+00:00",
        33=>4411260,
        41=>"0000000BUKALAPAK",
        2=>99501,
        4=>3600000000300000,
        11=>6,
        15=>"2020-01-07T00:00:00.000+00:00",
        26=>6021,
        32=>4410010,
        39=>"0000",
        48=>"00000005300000000011101#{bukopin_inquiry_reference_number}SUBCRIBER NAME           00005000000000000015  R10000013000000000002020010701202007012020000000300000C00000000000000000000000000000000000011110000222200000008000000080000000800000008", 61=>"8F21B5F4A5FFBE5E0B2C52E2F088BA06", 63=>"RINCIAN TAGIHAN DAPAT DIAKSES DI \"www.pln.co.id\" ATAU PLN TERDEKAT. Powered by Bukopinet."
      }
  }}

  let(:bukopin_inquiry_request_amount_mismatch_response) {{
    :status=>"success",
    :response_code=>"0000",
    :customer_number=>"530000000001",
    :customer_name=>"SUBCRIBER NAME           ",
    :segmentation=>"  R1",
    :power=>1300,
    :stand_meter=>"00001111 - 00002222",
    :outstanding_bill=>1,
    :unpaid_bill=>0,
    :admin_charge=>0,
    :amount=>300200,
    :reference_number=>"#{bukopin_inquiry_reference_number}",
    :bills=>[{:bill_period=>"202001",
      :due_date=>"07012020",
      :meter_read_date=>"07012020",
      :total_electricity_bill=>"000000300000",
      :incentive=>"C0000000000",
      :value_added_tax=>"0000000000",
      :penalty_fee=>0,
      :previous_meter_reading=>"00001111",
      :current_meter_reading=>"00002222",
      :previous_meter_reading_2=>"00000008",
      :current_meter_reading_2=>"00000008",
      :previous_meter_reading_3=>"00000008",
      :current_meter_reading_3=>"00000008",
      :amount=>300200,
      :previous_meter=>"00001111",
      :current_meter=>"00002222"}],
      :bill_status=>"1",
      :info_text=>"RINCIAN TAGIHAN DAPAT DIAKSES DI \"www.pln.co.id\" ATAU PLN TERDEKAT. Powered by Bukopinet.",
      :stan=>6,
      :raw_data=>{
        12=>"2020-01-07T09:15:11.000+00:00",
        33=>4411260,
        41=>"0000000BUKALAPAK",
        2=>99501,
        4=>3600000000300000,
        11=>6,
        15=>"2020-01-07T00:00:00.000+00:00",
        26=>6021,
        32=>4410010,
        39=>"0000",
        48=>"00000005300000000011101#{bukopin_inquiry_reference_number}SUBCRIBER NAME           00005000000000000015  R10000013000000000002020010701202007012020000000300000C00000000000000000000000000000000000011110000222200000008000000080000000800000008", 61=>"8F21B5F4A5FFBE5E0B2C52E2F088BA06", 63=>"RINCIAN TAGIHAN DAPAT DIAKSES DI \"www.pln.co.id\" ATAU PLN TERDEKAT. Powered by Bukopinet."
      }
  }}

  let(:bukopin_payment_iso_response) { '2210503200418281000A059950136000000003000000000000000062020010709151120200107602107441001007441126000000000000BUKALAPAK23700000005300000000011101044121CB5FF14476B83195DB922B05EBSUBCRIBER NAME           00005000000000000015  R10000013000000000002020010701202007012020000000300000C000000000000000000000000000000000000111100002222000000080000000800000008000000080328F21B5F4A5FFBE5E0B2C52E2F088BA06089RINCIAN TAGIHAN DAPAT DIAKSES DI \"www.pln.co.id\" ATAU PLN TERDEKAT. Powered by Bukopinet.' }
  let(:bukopin_payment_iso_request_obj) { Channel::Bukopin::ElectricityPostpaid::IsoMessage.decode('22005030004180810808059950136000000003000000000000000022020010812260260210744100100744112600000000BUKALAPAK23800000005300000000011110120984BB47152840C0E1F9E2ADA427B28SUBCRIBER NAME           00005000000000000015  R10000013000000000002020010701202007012020000000300000C00000000000000000000000000000000000011110000222200000008000000080000000800000008b20533d70c4b341203220984BB47152840C0E1F9E2ADA427B28') }
  let(:bukopin_payment_reference_number) { '20984BB47152840C0E1F9E2ADA427B28' }
  let(:bukopin_payment_request_response) {{
    :status=>"success",
    :response_code=>"0000",
    :customer_number=>"530000000001",
    :customer_name=>"SUBCRIBER NAME           ",
    :segmentation=>"  R1",
    :power=>1300,
    :stand_meter=>"00001111 - 00002222",
    :outstanding_bill=>1,
    :unpaid_bill=>0,
    :admin_charge=>0,
    :amount=>300000,
    :reference_number=>"#{bukopin_payment_reference_number}",
    :bills=>[{
      :bill_period=>"202001",
      :due_date=>"07012020",
      :meter_read_date=>"07012020",
      :total_electricity_bill=>"000000300000",
      :incentive=>"C0000000000",
      :value_added_tax=>"0000000000",
      :penalty_fee=>0,
      :previous_meter_reading=>"00001111",
      :current_meter_reading=>"00002222",
      :previous_meter_reading_2=>"00000008",
      :current_meter_reading_2=>"00000008",
      :previous_meter_reading_3=>"00000008",
      :current_meter_reading_3=>"00000008",
      :amount=>300000,
      :previous_meter=>"00001111",
      :current_meter=>"00002222"}],
    :bill_status=>"1",
    :info_text=>"",
    :stan=>2,
    :raw_data=> {
      12=>"2020-01-07T18:13:32.000+00:00",
      33=>4411260,
      41=>"0000000BUKALAPAK",
      2=>99501,
      4=>3600000000300000,
      11=>2,
      26=>6021,
      32=>4410010,
      39=>"0000",
      48=>"0000000530000000001101#{bukopin_payment_reference_number}SUBCRIBER NAME           00005000000000000015  R10000013000000000002020010701202007012020000000300000C00000000000000000000000000000000000011110000222200000008000000080000000800000008"
    }
  }}

  let(:bukopin_reversal_iso_response) { '241050300041828101000599501360000000030000000000000000420200109165428602107441001007441126000000000000BUKALAPAK23700000005300000000011101044121CB5FF8BB8A84EF5051CD8FB3FCSUBCRIBER NAME           00005000000000000015  R10000013000000000002020010901202009012020000000300000C00000000000000000000000000000000000011110000222200000008000000080000000800000008372200000000000004202001091654224410010' }
  let(:bukopin_reversal_request_response) {{ :status=>"failed", :response_code=>"0000", :message=>"Berhasil" }}
  let(:bukopin_reversal_reference_number) { '044121CB5FF14476B83195DB922B05EB' }

  def mock_bukopin_stan
    allow(Keystore)
      .to receive(:increment)
      .with(bukopin_unique_key)
      .and_return(stan)
  end

  def mock_bukopin_token
    allow_any_instance_of(Channel::Bukopin::ElectricityPostpaid::Requests::Base)
      .to receive(:get_token)
      .and_return(bukopin_token)
  end

  def mock_iso_connection(with: any_args, and_return: nil)
    allow(::Channel::Connection::Iso8583)
      .to receive(:send)
      .with(with)
      .and_return(and_return)
  end
end
