require "rails_helper"
include AuthHelper

RSpec.describe Partner::ElectricityPostpaid::AyoconnectController, type: :controller do
  describe 'O2OVPD-199 POST #callbacks' do
    context 'with right authentication' do
      before do
        http_login(ENV['OLYMPUS_USERNAME_FOR_AYOCONNECT'], ENV['OLYMPUS_PASSWORD_FOR_AYOCONNECT'])
      end

      it 'should return http Success 200' do
        post :callbacks
        expect(response).to have_http_status(:success)
        expect(response.status).to eq(200)
      end
    end

    context 'with wrong authentication' do
      before do
        http_login('wrongusername', 'wrongpassword')
      end

      it 'should return Unauthorized 401' do
        post :callbacks
        expect(response).to have_http_status(:unauthorized)
        expect(response.status).to eq(401)
      end
    end
  end
end
