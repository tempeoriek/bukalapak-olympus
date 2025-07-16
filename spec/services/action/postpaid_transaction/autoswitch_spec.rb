require "rails_helper"

class AutoswitchClass
  include Action::PostpaidTransaction::Autoswitch
end

RSpec.describe Action::PostpaidTransaction::Autoswitch do
  describe "#record_autoswitch_value" do
    let(:electricity_postpaid_class) { Action::ElectricityAutoswitch::Mechanism::Record.new(action: 'inquiry', status: :success) }
    let(:pdam_class) { Action::PdamAutoswitch::Mechanism::Record.new(action: 'inquiry', status: :success, operator_id: '1') }
    
    subject { AutoswitchClass.new }

    before do
      allow(Action::ElectricityAutoswitch::Mechanism::Record).to receive(:new).and_return(electricity_postpaid_class)
      allow(electricity_postpaid_class).to receive(:run!).and_return(true)

      allow(Action::PdamAutoswitch::Mechanism::Record).to receive(:new).and_return(pdam_class)
      allow(pdam_class).to receive(:run!).and_return(true)
    end

    context "when product type is Electricity Postpaid" do
      it "calls Action::ElectricityAutoswitch::Mechanism::Record.new with correct arguments" do
        expect(Action::ElectricityAutoswitch::Mechanism::Record).to receive(:new).with(action: 'inquiry', status: :success).and_return(electricity_postpaid_class)
        expect(electricity_postpaid_class).to receive(:run!)

        subject.record_autoswitch_value('inquiry', :success, :electricity_postpaid)
      end
    end

    context "when product type is PDAM" do
      it "calls Action::PDAMAutoswitch::Mechanism::Record.new with correct arguments" do
        expect(Action::PdamAutoswitch::Mechanism::Record).to receive(:new).with(action: 'inquiry', status: :success, operator_id: '1').and_return(pdam_class)
        expect(pdam_class).to receive(:run!)

        subject.record_autoswitch_value('inquiry', :success, :pdam, {operator_id: '1'})
      end
    end

    context "when product type is not recognized" do
      it "does not create action class" do
        expect(Action::ElectricityAutoswitch::Mechanism::Record).not_to receive(:new)
        expect(Action::PdamAutoswitch::Mechanism::Record).not_to receive(:new)
        expect(electricity_postpaid_class).not_to receive(:run!)
        expect(pdam_class).not_to receive(:run!)

        subject.record_autoswitch_value('inquiry', :success, :invalid_product)
      end
    end

    context "when autoswitch record is failed" do
      before do
        allow(Action::ElectricityAutoswitch::Mechanism::Record).to receive(:new).and_return(electricity_postpaid_class)
        allow(electricity_postpaid_class).to receive(:run!).and_raise('Error')
      end

      it "should log error" do
        expect(subject).to receive(:log_error).with("Failed to record autoswitch value Error", [:electricity_postpaid, 'autoswitch', 'record'], nil)

        subject.record_autoswitch_value('inquiry', :success, :electricity_postpaid)
      end
    end
  end
end
