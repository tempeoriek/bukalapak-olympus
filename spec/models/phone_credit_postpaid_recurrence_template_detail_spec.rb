require "rails_helper"

RSpec.describe PhoneCreditPostpaidRecurrenceTemplateDetail, type: :model do
  let(:template)        { build(:phone_credit_postpaid_recurrence_template_detail) }
  let(:provider)        { build(:phone_credit_provider) }
  let(:provider_prefix) { build(:provider_prefix) }

  let(:expected_json_response) {
    attributes_for(:phone_credit_postpaid_recurrence_template_detail).as_json.merge({
      provider: {
        name: provider.provider,
        product_name: provider.product_name,
        logo_url: provider.logo_url
      }.as_json
    }.as_json).merge({ 'customer_number': '081234000001' }.as_json)
  }

  context 'when record exist' do
    before do
      allow(ProviderPrefix).to receive(:find_by) { provider_prefix }
      allow(PhoneCreditProvider).to receive(:find) { provider }
    end

    it { expect(template.as_json).to include expected_json_response }
  end
end
