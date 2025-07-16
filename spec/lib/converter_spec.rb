# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Converter, type: :model do
  describe '.convert' do
    context 'year month and date' do
      test_cases = [
        {
          case_name: 'when provided the right date',
          values: '20220804',
          expected_error: nil,
          expected_return_value: Date.new(2022, 8, 4)
        },
        {
          case_name: 'when provided the wrong date',
          values: '20229999',
          expected_error: ArgumentError,
          expected_return_value: nil
        },
        {
          case_name: 'string not numeric',
          values: 'abcdefgh',
          expected_error: nil,
          expected_return_value: nil
        },
        {
          case_name: 'string not enough length',
          values: '2022090',
          expected_error: nil,
          expected_return_value: nil
        }
      ]
  
      test_cases.each do |tc|
        context "#{tc[:case_name]}" do
          subject { described_class::StringToDate.convert(tc[:values], string_format: Postpaid::Constant::YYYYMMDD) }

          it 'returns the expected value' do
            if tc[:expected_error].nil?
              expect { subject }.not_to raise_error
              expect(subject).to eq tc[:expected_return_value]
            else
              expect { subject }.to raise_error(tc[:expected_error])
            end
          end
        end
      end
    end

    context 'when using date month and year' do
      test_cases = [
        {
          case_name: 'when provided the right date',
          values: '04082022',
          expected_error: nil,
          expected_return_value: Date.new(2022, 8, 4)
        },
        {
          case_name: 'when provided the wrong date',
          values: '12345678',
          expected_error: ArgumentError,
          expected_return_value: nil
        },
        {
          case_name: 'string not numeric',
          values: 'abcdefgh',
          expected_error: nil,
          expected_return_value: nil
        },
        {
          case_name: 'string not enough length',
          values: '2022090',
          expected_error: nil,
          expected_return_value: nil
        }
      ]
  
      test_cases.each do |tc|
        context "#{tc[:case_name]}" do
          subject { described_class::StringToDate.convert(tc[:values], string_format: Postpaid::Constant::DDMMYYYY) }

          it 'returns the expected value' do
            if tc[:expected_error].nil?
              expect { subject }.not_to raise_error
              expect(subject).to eq tc[:expected_return_value]
            else
              expect { subject }.to raise_error(tc[:expected_error])
            end
          end
        end
      end
    end

    context 'when using year and month' do
      test_cases = [
        {
          case_name: 'when provided the right date',
          values: '202105',
          expected_error: nil,
          expected_return_value: Date.new(2021, 5, 1)
        },
        {
          case_name: 'when provided the wrong date',
          values: '123456',
          expected_error: ArgumentError,
          expected_return_value: nil
        },
        {
          case_name: 'string not numeric',
          values: 'abcdef',
          expected_error: nil,
          expected_return_value: nil
        },
        {
          case_name: 'string not enough length',
          values: '1222',
          expected_error: nil,
          expected_return_value: nil
        }
      ]
  
      test_cases.each do |tc|
        context "#{tc[:case_name]}" do
          subject { described_class::StringToDate.convert(tc[:values], string_format: Postpaid::Constant::YYYYMM) }

          it 'returns the expected value' do
            if tc[:expected_error].nil?
              expect { subject }.not_to raise_error
              expect(subject).to eq tc[:expected_return_value]
            else
              expect { subject }.to raise_error(tc[:expected_error])
            end
          end
        end
      end
    end

    context 'when using month and full year' do
      test_cases = [
        {
          case_name: 'when provided the right date',
          values: 'May2018',
          expected_error: nil,
          expected_return_value: Date.new(2018, 5, 1)
        },
        {
          case_name: 'when provided the wrong date',
          values: 'Hgg2020',
          expected_error: ArgumentError,
          expected_return_value: nil
        },
        {
          case_name: 'not a string',
          values: 202022,
          expected_error: nil,
          expected_return_value: nil
        },
        {
          case_name: 'string not enough length',
          values: '1222',
          expected_error: nil,
          expected_return_value: nil
        }
      ]
  
      test_cases.each do |tc|
        context "#{tc[:case_name]}" do
          subject { described_class::StringToDate.convert(tc[:values], string_format: Postpaid::Constant::MMMYYYY) }

          it 'returns the expected value' do
            if tc[:expected_error].nil?
              expect { subject }.not_to raise_error
              expect(subject).to eq tc[:expected_return_value]
            else
              expect { subject }.to raise_error(tc[:expected_error])
            end
          end
        end
      end

      context 'with all month mappings' do
        test_cases = [
          {
            case_name: 'when month is January',
            values: 'Jan2021',
            expected_return_value: Date.new(2021, 1, 1)
          },
          {
            case_name: 'when month is February',
            values: 'Feb2021',
            expected_return_value: Date.new(2021, 2, 1)
          },
          {
            case_name: 'when month is March',
            values: 'Mar2021',
            expected_return_value: Date.new(2021, 3, 1)
          },
          {
            case_name: 'when month is April',
            values: 'Apr2021',
            expected_return_value: Date.new(2021, 4, 1)
          },
          {
            case_name: 'when month is May',
            values: 'May2021',
            expected_return_value: Date.new(2021, 5, 1)
          },
          {
            case_name: 'when month is June',
            values: 'Jun2021',
            expected_return_value: Date.new(2021, 6, 1)
          },
          {
            case_name: 'when month is July',
            values: 'Jul2021',
            expected_return_value: Date.new(2021, 7, 1)
          },
          {
            case_name: 'when month is August',
            values: 'Aug2021',
            expected_return_value: Date.new(2021, 8, 1)
          },
          {
            case_name: 'when month is September',
            values: 'Sep2021',
            expected_return_value: Date.new(2021, 9, 1)
          },
          {
            case_name: 'when month is October',
            values: 'Oct2021',
            expected_return_value: Date.new(2021, 10, 1)
          },
          {
            case_name: 'when month is November',
            values: 'Nov2021',
            expected_return_value: Date.new(2021, 11, 1)
          },
          {
            case_name: 'when month is December',
            values: 'Dec2021',
            expected_return_value: Date.new(2021, 12, 1)
          }
        ]

        test_cases.each do |tc|
          context "#{tc[:case_name]}" do
            subject { described_class::StringToDate.convert(tc[:values], string_format: Postpaid::Constant::MMMYYYY) }
  
            it 'returns the expected value' do
              expect(subject).to eq tc[:expected_return_value]
            end
          end
        end
      end
    end

    context 'when using day abr month and full year' do
      test_cases = [
        {
          case_name: 'when provided the right date',
          values: '21-MAY-2021',
          expected_error: nil,
          expected_return_value: Date.new(2021, 5, 21)
        },
        {
          case_name: 'when provided the wrong date',
          values: '32-JAN-2022',
          expected_error: ArgumentError,
          expected_return_value: nil
        },
        {
          case_name: 'not a string',
          values: 202022,
          expected_error: nil,
          expected_return_value: nil
        },
        {
          case_name: 'string not enough length',
          values: '1222',
          expected_error: nil,
          expected_return_value: nil
        }
      ]
  
      test_cases.each do |tc|
        context "#{tc[:case_name]}" do
          subject { described_class::StringToDate.convert(tc[:values], string_format: Postpaid::Constant::DDMMMYYYY) }

          it 'returns the expected value' do
            if tc[:expected_error].nil?
              expect { subject }.not_to raise_error
              expect(subject).to eq tc[:expected_return_value]
            else
              expect { subject }.to raise_error(tc[:expected_error])
            end
          end
        end
      end

      context 'with all month mappings' do
        test_cases = [
          {
            case_name: 'when month is January',
            values: '21-JAN-2021',
            expected_return_value: Date.new(2021, 1, 21)
          },
          {
            case_name: 'when month is February',
            values: '21-FEB-2021',
            expected_return_value: Date.new(2021, 2, 21)
          },
          {
            case_name: 'when month is March',
            values: '21-MAR-2021',
            expected_return_value: Date.new(2021, 3, 21)
          },
          {
            case_name: 'when month is April',
            values: '21-APR-2021',
            expected_return_value: Date.new(2021, 4, 21)
          },
          {
            case_name: 'when month is May',
            values: '21-MAY-2021',
            expected_return_value: Date.new(2021, 5, 21)
          },
          {
            case_name: 'when month is June',
            values: '21-JUN-2021',
            expected_return_value: Date.new(2021, 6, 21)
          },
          {
            case_name: 'when month is July',
            values: '21-JUL-2021',
            expected_return_value: Date.new(2021, 7, 21)
          },
          {
            case_name: 'when month is August',
            values: '21-AUG-2021',
            expected_return_value: Date.new(2021, 8, 21)
          },
          {
            case_name: 'when month is September',
            values: '21-SEP-2021',
            expected_return_value: Date.new(2021, 9, 21)
          },
          {
            case_name: 'when month is October',
            values: '21-OCT-2021',
            expected_return_value: Date.new(2021, 10, 21)
          },
          {
            case_name: 'when month is November',
            values: '21-NOV-2021',
            expected_return_value: Date.new(2021, 11, 21)
          },
          {
            case_name: 'when month is December',
            values: '21-DEC-2021',
            expected_return_value: Date.new(2021, 12, 21)
          }
        ]

        test_cases.each do |tc|
          context "#{tc[:case_name]}" do
            subject { described_class::StringToDate.convert(tc[:values], string_format: Postpaid::Constant::DDMMMYYYY) }
  
            it 'returns the expected value' do
              expect(subject).to eq tc[:expected_return_value]
            end
          end
        end
      end

      context 'when using month and half year' do
        test_cases = [
          {
            case_name: 'when provided the right date',
            values: 'Jul24',
            expected_error: nil,
            expected_return_value: Date.new(2024, 7, 1)
          },
          {
            case_name: 'when provided the wrong date',
            values: 'Juc24',
            expected_error: nil,
            expected_return_value: nil
          },
          {
            case_name: 'not a string',
            values: 22024,
            expected_error: nil,
            expected_return_value: nil
          },
          {
            case_name: 'string not enough length',
            values: '1222',
            expected_error: nil,
            expected_return_value: nil
          }
        ]

        test_cases.each do |tc|
          context "#{tc[:case_name]}" do
            subject { described_class::StringToDate.convert(tc[:values], string_format: Postpaid::Constant::MMMYY) }

            it 'returns the expected value' do
              if tc[:expected_error].nil?
                expect { subject }.not_to raise_error
                expect(subject).to eq tc[:expected_return_value]
              else
                expect { subject }.to raise_error(tc[:expected_error])
              end
            end
          end
        end

        context 'with all month mappings' do
          test_cases = [
            {
              case_name: 'when month is January',
              values: 'Jan24',
              expected_return_value: Date.new(2024, 1, 1)
            },
            {
              case_name: 'when month is February',
              values: 'Feb24',
              expected_return_value: Date.new(2024, 2, 1)
            },
            {
              case_name: 'when month is March',
              values: 'Mar24',
              expected_return_value: Date.new(2024, 3, 1)
            },
            {
              case_name: 'when month is April',
              values: 'Apr24',
              expected_return_value: Date.new(2024, 4, 1)
            },
            {
              case_name: 'when month is May',
              values: 'May24',
              expected_return_value: Date.new(2024, 5, 1)
            },
            {
              case_name: 'when month is June',
              values: 'Jun24',
              expected_return_value: Date.new(2024, 6, 1)
            },
            {
              case_name: 'when month is July',
              values: 'Jul24',
              expected_return_value: Date.new(2024, 7, 1)
            },
            {
              case_name: 'when month is August',
              values: 'Aug24',
              expected_return_value: Date.new(2024, 8, 1)
            },
            {
              case_name: 'when month is September',
              values: 'Sep24',
              expected_return_value: Date.new(2024, 9, 1)
            },
            {
              case_name: 'when month is October',
              values: 'Oct24',
              expected_return_value: Date.new(2024, 10, 1)
            },
            {
              case_name: 'when month is November',
              values: 'Nov24',
              expected_return_value: Date.new(2024, 11, 1)
            },
            {
              case_name: 'when month is December',
              values: 'Dec24',
              expected_return_value: Date.new(2024, 12, 1)
            }
          ]

          test_cases.each do |tc|
            context "#{tc[:case_name]}" do
              subject { described_class::StringToDate.convert(tc[:values], string_format: Postpaid::Constant::MMMYY) }

              it 'returns the expected value' do
                expect(subject).to eq tc[:expected_return_value]
              end
            end
          end
        end
      end
    end
  end
end
