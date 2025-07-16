require 'rails_helper'

RSpec.describe ResponseGeneralizer::Quickpay, type: :model do
  let(:object_pdam) {
    {
      customer_number: '213100140124',
      customer_name: 'EDY RUDIANTO',
      paid_until: nil,
      operator: 'pdam_denpasar',
      biller: nil,
      provider_name: nil,
      provider_product_name: nil,
      provider_logo_url: nil,
      family_member_count: nil
    }
  }
  let(:object_bpjs) {
    {
      customer_number: '0000001424087537',
      customer_name: 'DINARTI LURAH',
      paid_until: '2017-10',
      operator: nil,
      biller: nil,
      provider_name: nil,
      provider_product_name: nil,
      provider_logo_url: nil,
      family_member_count: 2
    }
  }
  let(:object_electricity_postpaid) {
    {
      customer_number: '535753467222',
      customer_name: 'IR SUDARTOYO',
      paid_until: nil,
      operator: nil,
      biller: nil,
      provider_name: nil,
      provider_product_name: nil,
      provider_logo_url: nil,
      family_member_count: nil
    }
  }
  let(:object_phone_credit_postpaid) {
    {
      customer_number: '08159136906',
      customer_name: 'DWINA FEBRIA',
      paid_until: '2019-01-01',
      operator: nil,
      biller: nil,
      provider_name: 'Telkomsel',
      provider_product_name: 'Kartu Halo',
      provider_logo_url: 'https://s4.bukalapak.com/images/virtual_product/phone/telkomsel.png',
      family_member_count: nil
    }
  }
  let(:object_cc) {
    {
      customer_number: '5426-40XX-XXXX-4274',
      customer_name: 'Rahma Anissa',
      paid_until: nil,
      operator: nil,
      biller: 'BNI',
      provider_name: nil,
      provider_product_name: nil,
      provider_logo_url: nil,
      family_member_count: nil
    }
  }
  
  let(:remote_type_pdam) { 'pdam' }
  let(:remote_type_bpjs) { 'bpjs-kesehatan' }
  let(:remote_type_electricity_postpaid) { 'electricity_postpaid' }
  let(:remote_type_cc) { 'credit-card-bill' }
  let(:remote_type_phone_credit_postpaid) { 'phone-credit-postpaid' }

	let(:subject_pdam) { described_class.new(object_pdam, remote_type_pdam) }
	let(:subject_bpjs) { described_class.new(object_bpjs, remote_type_bpjs) }
	let(:subject_electricity_postpaid) { described_class.new(object_electricity_postpaid, remote_type_electricity_postpaid) }
	let(:subject_cc) { described_class.new(object_cc, remote_type_cc) }
  let(:subject_phone_credit_postpaid) { described_class.new(object_phone_credit_postpaid, remote_type_phone_credit_postpaid) }
  let(:phone_credit_postpaid_hash_provider) {
    {
      name: 'Telkomsel',
      product_name: 'Kartu Halo',
      logo_url: 'https://s4.bukalapak.com/images/virtual_product/phone/telkomsel.png'
    }
  }

  describe 'pdam' do
    context 'check attributes & description can be used' do 
      it {expect(subject_pdam.customer_number).to eq(object_pdam[:customer_number])}
      it {expect(subject_pdam.customer_name).to eq(object_pdam[:customer_name])}
      it {expect(subject_pdam.paid_until).to eq(object_pdam[:paid_until])}
      it {expect(subject_pdam.operator).to eq(object_pdam[:operator])}
      it {expect(subject_pdam.biller).to eq(object_pdam[:biller])}
      it {expect(subject_pdam.provider_name).to eq(object_pdam[:provider_name])}
      it {expect(subject_pdam.provider_product_name).to eq(object_pdam[:provider_product_name])}
      it {expect(subject_pdam.provider_logo_url).to eq(object_pdam[:provider_logo_url])}
      it {expect(subject_pdam.remote_type).to eq(remote_type_pdam)}
      # it {expect(subject_pdam.descriptions).to eq(nil)}
      it {expect(subject_pdam.amount).to eq(nil)}
      it {expect(subject_pdam.provider).to eq(nil)}
      it {expect(subject_pdam.image_url).to eq(nil)}
      it {expect(subject_pdam.due_day).to eq nil}
      it {expect(subject_pdam.descriptions[:customer_number]['pdam']).to eq 'Nomor Pelanggan'}
    end
  end

  describe 'bpjs' do
    context 'check attributes & description can be used' do 
      it {expect(subject_pdam.customer_number).to eq(object_pdam[:customer_number])}
      it {expect(subject_bpjs.customer_name).to eq(object_bpjs[:customer_name])}
      it {expect(subject_bpjs.paid_until).to eq(object_bpjs[:paid_until])}
      it {expect(subject_bpjs.operator).to eq(object_bpjs[:operator])}
      it {expect(subject_bpjs.biller).to eq(object_bpjs[:biller])}
      it {expect(subject_bpjs.provider_name).to eq(object_bpjs[:provider_name])}
      it {expect(subject_bpjs.provider_product_name).to eq(object_bpjs[:provider_product_name])}
      it {expect(subject_bpjs.provider_logo_url).to eq(object_bpjs[:provider_logo_url])}
      it {expect(subject_bpjs.remote_type).to eq(remote_type_bpjs)}
      # it {expect(subject_bpjs.descriptions).to eq(nil)}
      it {expect(subject_bpjs.amount).to eq(nil)}
      it {expect(subject_bpjs.provider).to eq(nil)}
      it {expect(subject_bpjs.image_url).to eq 'https://s4.bukalapak.com/images/virtual_product/logo_bpjs.png'}
      it {expect(subject_bpjs.due_day).to eq 10}
      it {expect(subject_bpjs.descriptions[:customer_number]['bpjs-kesehatan']).to eq 'No. Kepesertaan/No. VA Keluarga'}
    end
  end

  describe 'electricity_postpaid' do
    context 'check attributes & description can be used' do 
      it {expect(subject_electricity_postpaid.customer_number).to eq(object_electricity_postpaid[:customer_number])}
      it {expect(subject_electricity_postpaid.customer_name).to eq(object_electricity_postpaid[:customer_name])}
      it {expect(subject_electricity_postpaid.paid_until).to eq(object_electricity_postpaid[:paid_until])}
      it {expect(subject_electricity_postpaid.operator).to eq(object_electricity_postpaid[:operator])}
      it {expect(subject_electricity_postpaid.biller).to eq(object_electricity_postpaid[:biller])}
      it {expect(subject_electricity_postpaid.provider_name).to eq(object_electricity_postpaid[:provider_name])}
      it {expect(subject_electricity_postpaid.provider_product_name).to eq(object_electricity_postpaid[:provider_product_name])}
      it {expect(subject_electricity_postpaid.provider_logo_url).to eq(object_electricity_postpaid[:provider_logo_url])}
      it {expect(subject_electricity_postpaid.remote_type).to eq(remote_type_electricity_postpaid)}
      # it {expect(subject_electricity_postpaid.descriptions).to eq(nil)}
      it {expect(subject_electricity_postpaid.amount).to eq(nil)}
      it {expect(subject_electricity_postpaid.provider).to eq(nil)}
      it {expect(subject_electricity_postpaid.image_url).to eq 'https://s4.bukalapak.com/images/virtual_product/logo_pln.png'}
      it {expect(subject_electricity_postpaid.due_day).to eq 20}
      it {expect(subject_electricity_postpaid.descriptions[:customer_number]['electricity_postpaid']).to eq 'Nomor Meter/ID Pelanggan'}
    end
  end

  describe 'phone-credit-postpaid' do
    context 'check attributes & description can be used' do 
      it {expect(subject_phone_credit_postpaid.customer_number).to eq(object_phone_credit_postpaid[:customer_number])}
      it {expect(subject_phone_credit_postpaid.customer_name).to eq(object_phone_credit_postpaid[:customer_name])}
      it {expect(subject_phone_credit_postpaid.paid_until).to eq(object_phone_credit_postpaid[:paid_until])}
      it {expect(subject_phone_credit_postpaid.operator).to eq(object_phone_credit_postpaid[:operator])}
      it {expect(subject_phone_credit_postpaid.biller).to eq(object_phone_credit_postpaid[:biller])}
      it {expect(subject_phone_credit_postpaid.provider_name).to eq(object_phone_credit_postpaid[:provider_name])}
      it {expect(subject_phone_credit_postpaid.provider_product_name).to eq(object_phone_credit_postpaid[:provider_product_name])}
      it {expect(subject_phone_credit_postpaid.provider_logo_url).to eq(object_phone_credit_postpaid[:provider_logo_url])}
      it {expect(subject_phone_credit_postpaid.remote_type).to eq(remote_type_phone_credit_postpaid)}
      # it {expect(subject_phone_credit_postpaid.descriptions).to eq(nil)}
      it {expect(subject_phone_credit_postpaid.amount).to eq(nil)}
      it {expect(subject_phone_credit_postpaid.provider).to eq(phone_credit_postpaid_hash_provider)}
      it {expect(subject_phone_credit_postpaid.image_url).to eq nil}
      it {expect(subject_phone_credit_postpaid.due_day).to eq nil}
      it {expect(subject_phone_credit_postpaid.descriptions[:customer_number]['phone-credit-postpaid']).to eq 'Nomor Telepon'}
    end
  end

  describe 'credit-card-bill' do
    context 'check attributes & description can be used' do 
      it {expect(subject_cc.customer_number).to eq(object_cc[:customer_number])}
      it {expect(subject_cc.customer_name).to eq(object_cc[:customer_name])}
      it {expect(subject_cc.paid_until).to eq(object_cc[:paid_until])}
      it {expect(subject_cc.operator).to eq(object_cc[:operator])}
      it {expect(subject_cc.biller).to eq(object_cc[:biller])}
      it {expect(subject_cc.provider_name).to eq(object_cc[:provider_name])}
      it {expect(subject_cc.provider_product_name).to eq(object_cc[:provider_product_name])}
      it {expect(subject_cc.provider_logo_url).to eq(object_cc[:provider_logo_url])}
      it {expect(subject_cc.remote_type).to eq(remote_type_cc)}
      # it {expect(subject_cc.descriptions).to eq(nil)}
      it {expect(subject_cc.amount).to eq(nil)}
      it {expect(subject_cc.provider).to eq(nil)}
      it {expect(subject_cc.image_url).to eq nil}
      it {expect(subject_cc.due_day).to eq nil}
      it {expect(subject_phone_credit_postpaid.descriptions[:customer_number]['credit-card-bill']).to eq nil}
    end
  end
end
