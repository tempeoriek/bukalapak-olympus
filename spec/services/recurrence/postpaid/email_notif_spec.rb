require 'rails_helper'

RSpec.describe Recurrence::Postpaid::EmailNotif, type: :model do

  let(:template_map) do
    {
      topup_deposit: "olympus_recurrence_topup_deposit_#{payload_name}_payload",
      unsubscribe_success: "olympus_recurrence_unsubscribe_success_#{payload_name}_payload",
      subscribe_success: "olympus_recurrence_subscribe_success_#{payload_name}_payload",
      transaction_success: "olympus_recurrence_transaction_success_#{payload_name}_payload",
      transaction_error: "olympus_recurrence_transaction_error_#{payload_name}_payload"
    }
  end

  let(:today) { DateTime.strptime("2021-06-03", "%Y-%m-%d") }

  let(:expected_remote_id) { 123 }
  let(:expected_invoice_id) { 345 }
  let(:expected_amount) { 789 }
  let(:expected_date) { "2018-08-20" }
  let(:user_id) { template_detail.buyer_id }
  let(:electricity_postpaid_payload_map) do
    {
      topup_deposit: {
        product_name: postpaid_product,
        action_date: expected_date,
        customer_number: template_detail.customer_number
      },
      unsubscribe_success: {
        product_name: postpaid_product,
        action_date: today,
        customer_number: template_detail.customer_number
      },
      subscribe_success: {
        product_name: postpaid_product,
        action_date: expected_date,
        customer_number: template_detail.customer_number
      },
      transaction_success: {
        product_name: postpaid_product,
        customer_name: template_detail.customer_name,
        customer_number: template_detail.customer_number,
        power: template_detail.power,
        segmentation: template_detail.segmentation,
        action_date: today,
        remote_id: expected_remote_id,
        invoice_id: expected_remote_id,
        amount: expected_amount
      },
      transaction_error: {
        product_name: postpaid_product,
        customer_name: template_detail.customer_name,
        customer_number: template_detail.customer_number,
        power: template_detail.power,
        segmentation: template_detail.segmentation,
        action_date: today,
        remote_id: expected_remote_id,
        invoice_id: expected_remote_id,
        amount: expected_amount
      }
    }
  end
  let(:bpjs_kesehatan_payload_map) do
    {
      topup_deposit: {
        product_name: postpaid_product,
        action_date: expected_date,
        customer_number: template_detail.customer_number
      },
      unsubscribe_success: {
        product_name: postpaid_product,
        action_date: today,
        customer_number: template_detail.customer_number
      },
      subscribe_success: {
        product_name: postpaid_product,
        action_date: expected_date,
        customer_number: template_detail.customer_number
      },
      transaction_success: {
        product_name: postpaid_product,
        customer_name: template_detail.customer_name,
        customer_number: template_detail.customer_number,
        action_date: today,
        remote_id: expected_remote_id,
        invoice_id: expected_remote_id,
        amount: expected_amount
      },
      transaction_error: {
        product_name: postpaid_product,
        customer_name: template_detail.customer_name,
        customer_number: template_detail.customer_number,
        action_date: today,
        remote_id: expected_remote_id,
        invoice_id: expected_remote_id,
        amount: expected_amount
      }
    }
  end
  let(:pdam_payload_map) do
    {
      topup_deposit: {
        product_name: postpaid_product,
        action_date: expected_date,
        operator_name: "Denpasar",
        customer_number: template_detail.customer_number,
        customer_name: template_detail.customer_name
      },
      unsubscribe_success: {
        product_name: postpaid_product,
        action_date: today,
        customer_number: template_detail.customer_number
      },
      subscribe_success: {
        product_name: postpaid_product,
        action_date: expected_date,
        operator_name: "Denpasar",
        customer_number: template_detail.customer_number
      },
      transaction_success: {
        product_name: postpaid_product,
        customer_name: template_detail.customer_name,
        customer_number: template_detail.customer_number,
        operator_name: "Denpasar",
        action_date: today,
        remote_id: expected_remote_id,
        invoice_id: expected_remote_id,
        amount: expected_amount
      },
      transaction_error: {
        product_name: postpaid_product,
        customer_name: template_detail.customer_name,
        customer_number: template_detail.customer_number,
        operator_name: "Denpasar",
        action_date: today,
        remote_id: expected_remote_id,
        invoice_id: expected_remote_id,
        amount: expected_amount
      }
    }
  end
  let(:payload_map) do
    {
      'electricity_postpaid' => electricity_payload_map,
      'bpjs_kesehatan' => bpjs_payload_map,
      'pdam' => pdam_payload_map
    }
  end
  let(:product_payload_name_map) do
    {
      'electricity_postpaid' => 'postpaid_electricity',
      'bpjs_kesehatan' => 'bpjs_kesehatan',
      'pdam' => 'pdam'
    }
  end
  let(:product_factory_name_map) do
    {
      'electricity_postpaid' => :electricity_postpaid_recurrence_template_detail,
      'bpjs_kesehatan' => :bpjs_kesehatan_recurrence_template_detail,
      'pdam' => :pdam_recurrence_template_detail
    }
  end
  let(:user) do
    {
      email: 'marchell.imanuel@bukalapak.com',
      user_id: 147,
      name: 'ganteng'
    }
  end
  let(:payment_id) { 'BLALA123INV' }
  let(:invoice) do
    {
      payment_id: payment_id
    }
  end

  before do
    expect(Escrow::UserDetail).to receive(:get).with(user_id).and_return(user)
  end

  %w[electricity_postpaid bpjs_kesehatan pdam].each do |product|
    context "when sending notif for product #{product}" do
      [
        :topup_deposit,
        :unsubscribe_success,
        :subscribe_success,
        :transaction_success,
        :transaction_error,
      ].each do |notif_type|
        context "with #{notif_type} type" do
          let(:template_detail) { create(product_factory_name_map[product]) }

          let(:postpaid_product) { product }
          let(:payload_name) { product_payload_name_map[product] }
          let(:template) { template_map[notif_type] }
          let(:payload) { send("#{product}_payload_map")[notif_type] }

          let(:product_display_name) { MailerUtility::RECURRENCE_EMAIL_PRODUCT_NAME_MAPPER[payload[:product_name]] }
          let(:formatted_date) { DateTime.strptime(payload[:action_date].to_s, "%Y-%m-%d") if payload[:action_date].present? }

          let(:expected_email_subject) { MailerUtility::RECURRENCE_EMAIL_SUBJECT_MAPPER[notif_type] % [product_display_name, I18n.l(formatted_date, format: "%B %Y"), payment_id] }
          let(:expected_email_tag) { "#{product_display_name}_recurrence_#{notif_type}" }
          let(:expected_email_body) { File.read("spec/fixtures/recurrence_email/#{product}/#{notif_type}.html") } # get from fixtures
          let(:expected_email_payload) do
            {
              subject: expected_email_subject,
              tag: expected_email_tag,
              body: expected_email_body
            }
          end

          subject { described_class.new(template, user_id, payload).run! }

          before do
            expect(Escrow::InvoiceDetail).to receive(:get).with(payload[:invoice_id]).and_return(invoice) if payload[:invoice_id].present?
          end

          it 'sends the expected email payload' do
            expect(::Channel::Notif).to receive(:send_email) do |_user, _email_payload|
              # uncomment to update fixtures
              File.write("spec/fixtures/recurrence_email/#{product}/#{notif_type}.html", _email_payload[:body], { mode: 'w+' })

              expect(_user).to eq(user)
              expect(_email_payload).to eq(expected_email_payload)
            end

            expect{ subject }.not_to raise_error
          end
        end
      end
    end
  end

  context 'when user not found' do
    let(:user) { {} }
    let(:template_detail) { create(:bpjs_kesehatan_recurrence_template_detail) }


    subject { described_class.new('olympus_recurrence_topup_deposit_postpaid_electricity_payload', user_id, {}).run! }

    it { expect{ subject }.not_to raise_error }
    it { expect(subject).to eq false }
  end
end