class BpjsKesehatanQuickpaysController < PostpaidsController
  include Response::Quickpay

  PRODUCT_NAME = BPJS_KESEHATAN_PRODUCT

  def index
    raise Exceptions::UnauthorizedUser.new if decoded_token[:resource_owner_id] == 0
    return render json: {data: [], meta: {http_status: 200}}, status: 200 if decoded_token[:resource_owner][:agent]

    today = Time.now
    user_id = decoded_token[:resource_owner_id]

    transactions = Quickpays::Get.new('bpjs-kesehatan', today, user_id).run!

    skip_cache = params[:skip_cache] == "true" ? true : false
    results = Quickpays::Inquiry.new('bpjs-kesehatan', today, transactions, skip_cache).run!

    render json: {data: results, meta: {http_status: 200}}, status: 200
  end

  def delete
    raise Exceptions::UnauthorizedUser.new if decoded_token[:resource_owner_id] == 0 || decoded_token[:resource_owner][:agent]

    user_id = decoded_token[:resource_owner_id]
    Quickpays::Delete.new('bpjs-kesehatan', Time.now, user_id, params).run!

    render json: {message: 'Pengingat berhasil dihapus', meta: {http_status: 200}}, status: 200
  end
end
