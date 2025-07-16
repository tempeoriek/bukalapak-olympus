class ElectricityPostpaidsQuickpaysController < PostpaidsController
  include Response::Quickpay

  PRODUCT_NAME = ELECTRICITY_PRODUCT

  def index
    raise Exceptions::UnauthorizedUser.new if decoded_token[:resource_owner_id] == 0
    return render json: {data: [], meta: {http_status: 200}}, status: 200 if decoded_token[:resource_owner][:agent]

    today = Time.now
    user_id = decoded_token[:resource_owner_id]

    transactions = Quickpays::Get.new('electricity_postpaid', today, user_id).run!

    skip_cache = params[:skip_cache] == "true" ? true : false
    results = Quickpays::Inquiry.new('electricity_postpaid', today, transactions, skip_cache).run!

    render json: {data: results, meta: {http_status: status}}, status: status
  end

  def delete
    raise Exceptions::UnauthorizedUser.new if decoded_token[:resource_owner_id] == 0 || decoded_token[:resource_owner][:agent]

    user_id = decoded_token[:resource_owner_id]
    Quickpays::Delete.new('electricity_postpaid', Time.now, user_id, params).run!

    render json: {message: 'Pengingat berhasil dihapus', meta: {http_status: 200}}, status: 200
  end
end
