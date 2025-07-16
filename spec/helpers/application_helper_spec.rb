require 'rails_helper'

class DummyClass
  include ApplicationHelper
end

RSpec.describe ApplicationHelper, type: :model do
  describe '.snake_case' do
    let(:expected_positive_result) { 'testing_case' }

    context 'All Caps without space' do
      let(:string) { 'TESTINGCASE' }

      subject { DummyClass.new.snake_case(string) }

      it 'return all small caps' do
        expect(subject).to eq 'testingcase'
      end
    end

    context 'All Caps with space' do
      let(:string) { 'TESTING CASE' }

      subject { DummyClass.new.snake_case(string) }

      it 'return all small caps with underscore' do
        expect(subject).to eq expected_positive_result
      end
    end

    context 'CamelCase' do
      let(:string) { 'TestingCase' }

      subject { DummyClass.new.snake_case(string) }

      it 'return all small caps with underscore' do
        expect(subject).to eq expected_positive_result
      end
    end

    context 'Tilteize Case' do
      let(:string) { 'Testing Case' }

      subject { DummyClass.new.snake_case(string) }

      it 'return all small caps with underscore' do
        expect(subject).to eq expected_positive_result
      end
    end

    context 'Tilteize Case with dot char' do
      let(:string) { 'Te. Case' }

      subject { DummyClass.new.snake_case(string) }

      it 'return all small caps with underscore' do
        expect(subject).to eq 'te_case'
      end
    end

    # this test case intent to show that special char aside dot (.) are not processed.
    context 'Tilteize Case with other special char' do
      let(:string) { 'Te@Case' }

      subject { DummyClass.new.snake_case(string) }

      it 'return all small caps with underscore' do
        expect(subject).to eq 'te@case'
      end
    end
  end
end
