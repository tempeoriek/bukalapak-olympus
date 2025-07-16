require 'rails_helper'


class MockResponseCode
  include Channel::Thor::Helpers::ResponseCode
end

RSpec.describe Channel::Thor::Helpers::ResponseCode, type: :model do
  describe "#get_status_from_response_code" do
    context 'with action inquiry' do
      context 'when the rc is success' do
        MockResponseCode::SUCCESS_RC.each do |rc|
          it "returns success for rc #{rc}" do
            expect(MockResponseCode.new.get_status_from_response_code(:inquiry, rc)).to eq(:success)
          end
        end
      end

      context 'when the rc is failed' do
        MockResponseCode::FAILED_RC.keys.each do |rc|
          it "returns failed for rc #{rc}" do
            expect(MockResponseCode.new.get_status_from_response_code(:inquiry, rc)).to eq(:failed)
          end
        end
      end

      context 'when the rc is unknown' do
        let(:rc) { '0666' }

        it 'returns error for rc 0666' do
          expect(MockResponseCode.new.get_status_from_response_code(:inquiry, rc)).to eq(:error)
        end
      end
    end

    context 'with action create_transaction' do
      context 'when the rc is success' do
        MockResponseCode::SUCCESS_RC.each do |rc|
          it "returns success for rc #{rc}" do
            expect(MockResponseCode.new.get_status_from_response_code(:create_transaction, rc)).to eq(:success)
          end
        end
      end

      context 'when the rc is pending' do
        MockResponseCode::TRANSACTION_PENDING_RC.each do |rc|
          it "returns failed for rc #{rc}" do
            expect(MockResponseCode.new.get_status_from_response_code(:create_transaction, rc)).to eq(:pending)
          end
        end
      end

      context 'when the rc is failed' do
        MockResponseCode::TRANSACTION_FAILED_RC.keys.each do |rc|
          it "returns failed for rc #{rc}" do
            expect(MockResponseCode.new.get_status_from_response_code(:create_transaction, rc)).to eq(:failed)
          end
        end
      end

      context 'when the rc is unknown' do
        let(:rc) { '0666' }

        it 'returns error for rc 0666' do
          expect(MockResponseCode.new.get_status_from_response_code(:create_transaction, rc)).to eq(:error)
        end
      end
    end

    context 'when action get_transaction_by_id' do
      context 'when the rc is success' do
        MockResponseCode::SUCCESS_RC.each do |rc|
          it "returns success for rc #{rc}" do
            expect(MockResponseCode.new.get_status_from_response_code(:get_transaction_by_id, rc)).to eq(:success)
          end
        end
      end

      context 'when the rc is failed' do
        MockResponseCode::TRANSACTION_FAILED_RC.except(*MockResponseCode::TRANSACTION_UNAVAILABLE_RC, *MockResponseCode::ADVICE_PENDING_RC).keys.each do |rc|
          it "returns failed for rc #{rc}" do
            expect(MockResponseCode.new.get_status_from_response_code(:get_transaction_by_id, rc)).to eq(:failed)
          end
        end
      end

      context 'when the rc is unknown' do
        let(:rc) { '0666' }

        it 'returns error for rc 0666' do
          expect(MockResponseCode.new.get_status_from_response_code(:get_transaction_by_id, rc)).to eq(:error)
        end
      end

      context 'when the rc is pending' do
        (MockResponseCode::TRANSACTION_PENDING_RC + MockResponseCode::ADVICE_PENDING_RC).each do |rc|
          it "returns failed for rc #{rc}" do
            expect(MockResponseCode.new.get_status_from_response_code(:get_transaction_by_id, rc)).to eq(:pending)
          end
        end
      end
    end
  end

  describe '#failed_response?' do
    context 'when the rc is success' do
      MockResponseCode::SUCCESS_RC.each do |rc|
        it "returns success for rc #{rc}" do
          expect(MockResponseCode.new.failed_response?(rc)).to eq(false)
        end
      end
    end

    context 'when the rc is failed' do
      MockResponseCode::FAILED_RC.keys.each do |rc|
        it "returns success for rc #{rc}" do
          expect(MockResponseCode.new.failed_response?(rc)).to eq(true)
        end
      end
    end
  end

  describe '#partner_failed_response?' do
    context 'when the rc is partner failed' do
      MockResponseCode::PARTNER_FAILED_RC.each do |rc|
        it "returns success for rc #{rc}" do
          expect(MockResponseCode.new.partner_failed_response?(rc)).to eq(true)
        end
      end
    end

    context 'when the rc is not partner failed' do
      ['0009', '0013', '0014'].each do |rc|
        it "returns failed for rc #{rc}" do
          expect(MockResponseCode.new.partner_failed_response?(rc)).to eq(false)
        end
      end
    end

    context 'when the rc is not listed in failed rc' do
      it "returns success for unknown rc (1234)" do
        expect(MockResponseCode.new.partner_failed_response?('1234')).to eq(true)
      end
    end
  end

  describe '#raise_failed_inquiry!' do
    subject { MockResponseCode.new.raise_failed_inquiry!(rc, product_type, message) }
    let(:product_type) { 'pdam' }

    context 'when response code not include in failed rc' do
      let(:rc) { '0666' }
      let(:message) { nil }

      it 'should raise error TransactionCannotBeDone' do
        expect { subject }.to raise_error(Exceptions::TransactionCannotBeDone)
      end
    end

    context 'when response code include in failed rc' do
      let(:rc) { '0014' }
      let(:message) { nil }

      it 'should raise error UnregisteredNumber' do
        expect { subject }.to raise_error(Exceptions::UnregisteredNumber, 'Nomor tidak terdaftar. Coba periksa lagi, yuk.')
      end
    end

    context 'when response code include in failed rc' do
      let(:rc) { '0089' }
      let(:message) { 'bill already paid' }

      it 'should raise error BillAlreadyPaid' do
        expect { subject }.to raise_error(Exceptions::BillAlreadyPaid, 'Tagihan tidak ditemukan atau sudah dibayar.')
      end
    end

    context 'when product is electricity_postpaid' do
      let(:product_type) { 'electricity_postpaid' }

      context 'when response code is unregistered number' do
        let(:rc) { '0014' }
  
        context 'and have message' do
          let(:message) { 'IDPEL YANG ANDA MASUKKAN SALAH, MOHON TELITI KEMBALI.' }

          it 'should raise error UnregisteredNumber' do
            expect { subject }.to raise_error(Exceptions::UnregisteredNumber, 'IDPEL YANG ANDA MASUKKAN SALAH, MOHON TELITI KEMBALI.')
          end
        end

        context 'and does not have message' do
          let(:message) { nil }
          
          it 'should raise error UnregisteredNumber' do
            expect { subject }.to raise_error(Exceptions::UnregisteredNumber, 'Nomor tidak terdaftar. Coba periksa lagi, yuk.')
          end
        end
      end

      context 'when response code is account suspended' do
        let(:rc) { '0077' }
  
        context 'and have message' do
          let(:message) { 'KONSUMEN IDPEL 1234567890 DIBLOKIR HUBUNGI PLN' }

          it 'should raise error AccountSuspended' do
            expect { subject }.to raise_error(Exceptions::AccountSuspended, 'KONSUMEN IDPEL 1234567890 DIBLOKIR HUBUNGI PLN')
          end
        end

        context 'and does not have message' do
          let(:message) { nil }
          
          it 'should raise error AccountSuspended' do
            expect { subject }.to raise_error(Exceptions::AccountSuspended, 'Nomor terblokir.')
          end
        end
      end

      context 'when response code is bill already paid' do
        let(:rc) { '0089' }
  
        context 'and have message' do
          let(:message) { 'TAGIHAN BULAN NOVEMBER BELUM TERSEDIA' }

          it 'should raise error BillAlreadyPaid' do
            expect { subject }.to raise_error(Exceptions::BillAlreadyPaid, 'TAGIHAN BULAN NOVEMBER BELUM TERSEDIA')
          end
        end

        context 'and does not have message' do
          let(:message) { nil }
          
          it 'should raise error BillAlreadyPaid' do
            expect { subject }.to raise_error(Exceptions::BillAlreadyPaid, 'Tagihan tidak ditemukan atau sudah dibayar.')
          end
        end
      end

      context 'when response code is cut off' do
        let(:rc) { '0090' }
  
        context 'and have message' do
          let(:message) { 'SEDANG BERLANGSUNG PROSES CUTOFF, SILAHKAN COBA BEBERAPA SAAT KEMUDIAN' }

          it 'should raise error Thor::CutOff' do
            expect { subject }.to raise_error(Exceptions::Thor::CutOff, 'SEDANG BERLANGSUNG PROSES CUTOFF, SILAHKAN COBA BEBERAPA SAAT KEMUDIAN')
          end
        end

        context 'and does not have message' do
          let(:message) { nil }
          
          it 'should raise error Thor::CutOff' do
            expect { subject }.to raise_error(Exceptions::Thor::CutOff, 'Cut Off System')
          end
        end
      end
    end

    context 'when response code include in failed rc with default error' do
      let(:rc) { '0036' }

      context 'when message is nil' do
        let(:message) { nil }

        it 'should raise error DefaultError' do
          expect { subject }.to raise_error(Exceptions::Thor::DefaultError, 'Terjadi kesalahan pada sistem')
        end
      end

      context 'when message is not nil' do
        let(:message) { 'duplicate order id' }

        it 'should raise error DefaultError' do
          expect { subject }.to raise_error(Exceptions::Thor::DefaultError, message)
        end
      end
    end
  end
end
