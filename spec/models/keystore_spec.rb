require "rails_helper"

describe Keystore, type: :model do
  let(:key) { attributes_for(:keystore)[:key] }
  let(:keystore) { build(:keystore) }

  it { expect(keystore.valid?).to be true }

  subject { described_class }
  it { expect(subject).to respond_to(:get) }
  it { expect(subject).to respond_to(:set) }
  it { expect(subject).to respond_to(:expire) }
  it { expect(subject).to respond_to(:expireat) }
  it { expect(subject).to respond_to(:increment) }

  context 'invalid keys' do
    it { expect { subject.get('not_a_valid_key') }.to raise_error(Exceptions::KeyNotAllowed) }
    it { expect { subject.set('not_a_valid_key', 1) }.to raise_error(Exceptions::KeyNotAllowed) }
    it { expect { subject.del('not_a_valid_key') }.to raise_error(Exceptions::KeyNotAllowed) }
    it { expect { subject.expire('not_a_valid_key') }.to raise_error(Exceptions::KeyNotAllowed) }
    it { expect { subject.expireat('not_a_valid_key', 1) }.to raise_error(Exceptions::KeyNotAllowed) }
    it { expect { subject.increment('not_a_valid_key') }.to raise_error(Exceptions::KeyNotAllowed) }
  end

  context 'with ttl' do
    let(:keystore) { build(:keystore, :with_expired_ttl) }

    it 'return nil when expired' do
      expect(subject).to receive(:find_by_key).with(key).and_return keystore

      expect(subject.get(key)).to be_nil
    end
  end

  context 'when key have store value with ttl' do
    let(:keystore) { build(:keystore, :with_ttl) }

    it 'should reset ttl' do
      expect(subject).to receive(:find_by_key).with(key).and_return keystore

      expect(subject.get(key)).not_to be_nil

      expect(subject).to receive(:find_or_initialize_by).with(key: key).and_return keystore

      subject.set(key, 'new_value')

      expect(keystore.value).to eq 'new_value'
      expect(keystore.expiration_time).to be_nil
    end
  end

  context 'when try to increment' do
    let(:keystore) { build(:keystore) }

    it 'should be able to increase nil value' do
      expect(subject).to receive(:find_or_initialize_by).with(key: key).and_return keystore

      expect(subject.increment(key)).to eq 1

      expect(keystore.value).to eq '1'
    end

    let(:int_keystore) { build(:keystore, value: '10') }

    it 'should be able to increase numeric string value' do
      expect(subject).to receive(:find_or_initialize_by).with(key: key).and_return int_keystore

      expect(subject.increment(key)).to eq 11

      expect(int_keystore.value).to eq '11'
    end

    let(:str_keystore) { build(:keystore, value: 'bhahaha') }

    it 'should be able to increase numeric string value' do
      expect(subject).to receive(:find_or_initialize_by).with(key: key).and_return str_keystore

      expect{ subject.increment(key) }.to raise_error(Exceptions::NonIntegerValue)
    end
  end

  context 'when try to expire' do
    let(:keystore) { build(:keystore, :with_ttl) }

    it 'should return nil value when expire' do
      expect(subject).to receive(:find_by_key).with(key).and_return keystore

      expect(keystore.value).not_to be_nil
      expect(keystore.expiration_time).not_to be_nil

      subject.expire(key)

      expect(keystore.value).to be_nil
      expect(keystore.expiration_time).to be_nil
    end
  end
end
