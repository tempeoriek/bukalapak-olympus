require 'rails_helper'
require 'support/electricity_mocks'
include Postpaid::Constant

RSpec.describe Channel::Bukopin::ElectricityPostpaid, type: :model do
  include_context "electricity_mocks"

  let(:form) { Form::ElectricityPostpaid.new(customer_number, "NO_USERNAME", nil, buyer_type) }
  let(:elp_partner_bukopin) { build_stubbed(:electricity_postpaid_partner, :bukopin) }
  let(:elp_transaction) { build(:postpaid_transaction_with_bill, :partner_bukopin, :paid, amount: 300000) }

  before do
    allow(::ElectricityPostpaidPartner)
      .to receive(:find_by)
      .and_return(elp_partner_bukopin)
  end

  def mock_successful_inquiry
    allow(Channel::Bukopin::ElectricityPostpaid::Requests::Inquiry)
      .to receive(:new)
      .with(anything, buyer_type: buyer_type)
      .and_call_original
    allow_any_instance_of(Channel::Bukopin::ElectricityPostpaid::Requests::Inquiry)
      .to receive(:run!)
      .and_return(bukopin_inquiry_request_response)
  end

  def mock_successful_inquiry_payment
    allow(Channel::Bukopin::ElectricityPostpaid::Requests::Inquiry)
      .to receive(:new)
      .with(anything, buyer_type: buyer_type, read_timeout: 40, track_id: 1)
      .and_call_original
    allow_any_instance_of(Channel::Bukopin::ElectricityPostpaid::Requests::Inquiry)
      .to receive(:run!)
      .and_return(bukopin_inquiry_request_response)
  end

  describe '.inquiry_to_partner' do
    subject { described_class.new(form) }

    context 'WITH NORMAL_BUYER_TYPE' do
      let(:buyer_type) { NORMAL_BUYER_TYPE }

      context 'when inquiry is successful' do
        it 'should return a valid object' do
          mock_successful_inquiry

          response = subject.inquiry_to_partner
          expect(response).to be_a_kind_of(ResponseGeneralizer::ElectricityPostpaid)

          # Assert important attributes
          expect(response.customer_number).to eq(customer_number)
          expect(response.amount).not_to be_nil
          expect(response.reference_number).not_to be_nil
        end
      end

      context 'when inquiry raises error' do
        it 'should raise error' do
          expect(Channel::Bukopin::ElectricityPostpaid::Requests::Inquiry)
            .not_to receive(:new)
            .with(anything, buyer_type: buyer_type, read_timeout: 40, track_id: 1)
            .and_call_original
          allow_any_instance_of(Channel::Bukopin::ElectricityPostpaid::Requests::Inquiry)
            .to receive(:run!)
            .and_raise(Exceptions::Bukopin::Inquiry)

          expect { subject.inquiry_to_partner }.to raise_error
        end
      end

      context 'when inquiry during cutoff time' do
        let(:time_in_the_middle_of_cutoff) { subject.tclose + ((subject.topen + 1.day - subject.tclose) / 2) }

        it 'should raise ClosedTimeError error' do
          # Unstub `is_closed_time?`
          allow_any_instance_of(Channel::Bukopin::ElectricityPostpaid).to receive(:is_closed_time?).and_call_original
          allow(Time).to receive_message_chain(:zone, :now).and_return(time_in_the_middle_of_cutoff)
          expect { subject.inquiry_to_partner }.to raise_error(::Exceptions::ClosedTimeError)
        end
      end
    end

    context 'WITH AGENT_BUYER_TYPE' do
      let(:buyer_type) { AGENT_BUYER_TYPE }
      before do
        allow(Toggles::BukopinMitraAuth).to receive(:active?).and_return true
      end

      context 'when inquiry is successful' do
        it 'should return a valid object' do
          mock_successful_inquiry

          response = subject.inquiry_to_partner
          expect(response).to be_a_kind_of(ResponseGeneralizer::ElectricityPostpaid)

          # Assert important attributes
          expect(response.customer_number).to eq(customer_number)
          expect(response.amount).not_to be_nil
          expect(response.reference_number).not_to be_nil
        end
      end
    end
  end


  describe '.create_transaction' do
    subject { described_class.new(elp_transaction) }

    context 'with NORMAL_BUYER_TYPE' do
      let(:buyer_type) { NORMAL_BUYER_TYPE }

      context 'when inquiry raises error' do
        it 'should raise the error' do
          allow_any_instance_of(Channel::Bukopin::ElectricityPostpaid::Requests::Inquiry)
            .to receive(:run!)
            .and_raise(Exceptions::Bukopin::Inquiry)

          expect { subject.create_transaction }.to raise_error
        end
      end

      context 'when inquiry is successful' do
        before { mock_successful_inquiry_payment }

        context 'and payment is successful' do
          before do
            allow_any_instance_of(Channel::Bukopin::ElectricityPostpaid::Requests::Payment)
              .to receive(:run!)
              .and_return(bukopin_payment_request_response)
          end

          it 'should update reference number based on inquiry response' do
            response = subject.create_transaction
            expect(elp_transaction.reference_number).to eq(bukopin_inquiry_reference_number)
          end

          it 'should return a valid object' do
            response = subject.create_transaction
            expect(response).to be_kind_of(ResponseGeneralizer::ElectricityPostpaid)
            # Assert important attributes
            expect(response.reference_number).to eq(bukopin_payment_reference_number)
            expect(response.status).not_to be_nil
          end
        end

        context 'when got mismatch amount' do
          before do
            allow_any_instance_of(Channel::Bukopin::ElectricityPostpaid::Requests::Inquiry)
              .to receive(:run!)
              .and_return(bukopin_inquiry_request_amount_mismatch_response)
          end

          it 'will raise mismatch error exception' do
            expect{subject.create_transaction}.to raise_error Exceptions::AmountMismatch
          end
        end

        context 'and payment raises other errors' do
          it 'should raise the error' do
            allow_any_instance_of(Channel::Bukopin::ElectricityPostpaid::Requests::Payment)
              .to receive(:run!)
              .and_raise(StandardError)
            expect { subject.run! }.to raise_error
          end
        end

        context 'and payment times out or raises SystemCallError' do
          before do
            allow(Toggles::BukopinMitraAuth).to receive(:active?).and_return true
            mock_bukopin_token
          end

          context 'and when reverse is timeout once then successful' do
            before do
              expect(::Channel::Connection::Iso8583).to receive(:send).and_raise(Exceptions::SocketConnectionTimeout).twice
              expect(::Channel::Connection::Iso8583).to receive(:send).and_return(bukopin_reversal_iso_response).once
              allow(Channel::Bukopin::ElectricityPostpaid::Requests::Reversal)
                .to receive(:new)
                .with(
                  kind_of(Channel::Bukopin::ElectricityPostpaid::IsoMessage),
                  hash_including(:track_id, :buyer_type, :retry_count)
                ).and_call_original
            end

            it 'should return a valid object' do
              response = subject.create_transaction
              expect(response).to be_kind_of(ResponseGeneralizer::ElectricityPostpaid)
              # Assert important attributes
              expect(response.reference_number).to eq(bukopin_reversal_reference_number)
              expect(response.status).to eq(3)
            end
          end

          context 'and when reverse keeps on timing out or raises SystemCallError' do
            before do
              allow_any_instance_of(Channel::Bukopin::ElectricityPostpaid::Requests::Payment)
              .to receive(:run!)
              .and_raise(Exceptions::SocketConnectionTimeout)
              expect(Channel::Bukopin::ElectricityPostpaid::Requests::Reversal)
                .to receive(:new)
                .with(anything, retry_count: anything, track_id: kind_of(Integer), buyer_type: buyer_type)
                .and_call_original.exactly(3).times
              allow_any_instance_of(Channel::Bukopin::ElectricityPostpaid::Requests::Reversal)
                .to receive(:run!)
                .and_raise(Errno::ECONNREFUSED)
            end

            it 'should return a `stuck` response (pending)' do
              response = subject.create_transaction
              expect(response.status).to eq(Postpaid::Constant::PENDING)
            end
          end
        end
      end
    end

    context 'with AGENT_BUYER_TYPE' do
      let(:buyer_type) { AGENT_BUYER_TYPE }
      let(:elp_transaction) { build(:postpaid_transaction_with_bill, :partner_bukopin, :agent, :paid, amount: 300000) }

      before do
        allow(Toggles::BukopinMitraAuth).to receive(:active?).and_return true
      end

      context 'when inquiry is successful' do
        before { mock_successful_inquiry_payment }

        context 'and payment is successful' do
          before do
            allow_any_instance_of(Channel::Bukopin::ElectricityPostpaid::Requests::Payment)
              .to receive(:run!)
              .and_return(bukopin_payment_request_response)
          end

          it 'should update reference number based on inquiry response' do
            response = subject.create_transaction
            expect(elp_transaction.reference_number).to eq(bukopin_inquiry_reference_number)
          end

          it 'should return a valid object' do
            response = subject.create_transaction
            expect(response).to be_kind_of(ResponseGeneralizer::ElectricityPostpaid)
            # Assert important attributes
            expect(response.reference_number).to eq(bukopin_payment_reference_number)
            expect(response.status).not_to be_nil
          end
        end

        context 'when got mismatch amount' do
          before do
            allow_any_instance_of(Channel::Bukopin::ElectricityPostpaid::Requests::Inquiry)
              .to receive(:run!)
              .and_return(bukopin_inquiry_request_amount_mismatch_response)
          end

          it 'will raise mismatch error exception' do
            expect{subject.create_transaction}.to raise_error Exceptions::AmountMismatch
          end
        end

        context 'and payment raises other errors' do
          it 'should raise the error' do
            allow_any_instance_of(Channel::Bukopin::ElectricityPostpaid::Requests::Payment)
              .to receive(:run!)
              .and_raise(StandardError)
            expect { subject.run! }.to raise_error
          end
        end

        context 'and payment times out or raises SystemCallError' do
          before do
            allow_any_instance_of(Channel::Bukopin::ElectricityPostpaid::Requests::Payment)
              .to receive(:run!)
              .and_raise(Exceptions::SocketConnectionTimeout)
          end

          context 'and when reverse is successful' do
            before do
              allow_any_instance_of(Channel::Bukopin::ElectricityPostpaid::Requests::Reversal)
                .to receive(:run!)
                .and_return(bukopin_payment_request_response)
            end

            it 'should return a valid object' do
              response = subject.create_transaction
              expect(response).to be_kind_of(ResponseGeneralizer::ElectricityPostpaid)
              # Assert important attributes
              expect(response.reference_number).to eq(bukopin_payment_reference_number)
              expect(response.status).not_to be_nil
            end
          end

          context 'and when reverse keeps on timing out or raises SystemCallError' do
            before do
              expect(Channel::Bukopin::ElectricityPostpaid::Requests::Reversal)
                .to receive(:new)
                .with(anything, retry_count: anything, track_id: kind_of(Integer), buyer_type: buyer_type)
                .and_call_original.exactly(3).times
              allow_any_instance_of(Channel::Bukopin::ElectricityPostpaid::Requests::Reversal)
                .to receive(:run!)
                .and_raise(Errno::ECONNREFUSED)
            end

            it 'should return a `stuck` response (pending)' do
              response = subject.create_transaction
              expect(response.status).to eq(Postpaid::Constant::PENDING)
            end
          end
        end
      end
    end
  end
end
