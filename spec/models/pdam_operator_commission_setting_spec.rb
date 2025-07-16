require 'rails_helper'

RSpec.describe PdamOperatorCommissionSetting, type: :model do
    describe 'O2OVPE-927: validations' do
        let(:pdam_operator) { PdamOperator.create(name: 'Operator') }
        subject do
            described_class.new(
                value: 10,
                min_transaction_value: 0,
                max_transaction_value: 100,
                pdam_operator: pdam_operator,
                state: 'active'
            )
        end

        it 'is valid with valid attributes' do
            expect(subject).to be_valid
        end

        it 'is not valid without a value' do
            subject.value = nil
            expect(subject).not_to be_valid
        end

        it 'is not valid with a negative or non-integer value' do
            subject.value = -10
            expect(subject).not_to be_valid

            subject.value = 10.5
            expect(subject).not_to be_valid
        end

        it 'is not valid without a min_transaction_value' do
            subject.min_transaction_value = -1
            expect(subject).not_to be_valid
        end

        it 'is not valid with a negative or non-integer min_transaction_value' do
            subject.min_transaction_value = -10
            expect(subject).not_to be_valid

            subject.min_transaction_value = 10.5
            expect(subject).not_to be_valid
        end

        it 'is not valid without a max_transaction_value' do
            subject.max_transaction_value = nil
            expect(subject).not_to be_valid
        end

        it 'is not valid with a negative or non-integer max_transaction_value' do
            subject.max_transaction_value = -10
            expect(subject).not_to be_valid

            subject.max_transaction_value = 10.5
            expect(subject).not_to be_valid
        end

        it 'is not valid when min_transaction_value is greater than max_transaction_value' do
            subject.min_transaction_value = 100
            subject.max_transaction_value = 50
            expect(subject).not_to be_valid
        end

        it 'is not valid without a state' do
            subject.state = nil
            expect(subject).not_to be_valid
        end

        it 'is not valid when state is invalid' do
            subject.state = ''
            expect(subject).not_to be_valid
        end

        it 'is not valid when pdam_operator_id already exists' do
            PdamOperatorCommissionSetting.create!(
                value: 10,
                min_transaction_value: 0,
                max_transaction_value: 100,
                state: 'active',
                pdam_operator_id: pdam_operator.id
            )
            subject.pdam_operator_id = pdam_operator.id
            expect(subject).not_to be_valid
        end
    end
end
