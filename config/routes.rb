Rails.application.routes.draw do
  root to: proc { [404, {}, ["Not found."]] }
  # for readyness
  get  "/healthz" => "application#healthz"

  # old electricity postpaid
  # public
  post "/postpaid-inquiries" => "electricity_postpaids#inquiries"
  post "/postpaid-transactions" => "electricity_postpaids#create"
  get  "/postpaid-transactions/:id" => "electricity_postpaids#show"
  # internal
  post "/postpaid-transactions/invoicing" => "electricity_postpaids#invoicing"
  post "/postpaid-transactions/pay" => "electricity_postpaids#pay"
  post "/postpaid-transactions/confirm" => "electricity_postpaids#confirm"

  # old bpjs
  # public
  post "/inquiries" => "bpjs_kesehatan#inquiries"
  post "/transactions" => "bpjs_kesehatan#create"
  get  "/transactions/:id" => "bpjs_kesehatan#show"
  # internal
  post "/transactions/pay" => "bpjs_kesehatan#pay"
  post "/transactions/invoicing" => "bpjs_kesehatan#invoicing"
  post "/transactions/confirm" => "bpjs_kesehatan#confirm"

  # new electricities
  # public
  post "/electricities/postpaid-inquiries" => "electricity_postpaids#inquiries"
  get "/electricities/postpaid-inquiries/quickpays" => "electricity_postpaids_quickpays#index"
  delete "/electricities/postpaid-inquiries/quickpays" => "electricity_postpaids_quickpays#delete"
  post "/electricities/postpaid-transactions" => "electricity_postpaids#create"
  get  "/electricities/postpaid-transactions/:id" => "electricity_postpaids#show"
  get  "/electricities/postpaid-transactions/:id/receipt" => "electricity_postpaids#get_receipt"
  get  "/electricities/postpaid-transactions" => "electricity_postpaids#has_transacted"
  # recurrence
  post "/electricities/postpaid-recurrences/template-details" => "recurrence/electricity_postpaid/template_details#create"
  get  "/electricities/postpaid-recurrences/template-details/:id" => "recurrence/electricity_postpaid/template_details#show"
  post "_internal/electricities/postpaid-recurrences" => "recurrence/electricity_postpaid/internal#create"
  post "_internal/electricities/postpaid-recurrences/notify-balance" => "recurrence/electricity_postpaid/internal#notify_balance"
  post "_internal/electricities/postpaid-recurrences/notify-stop" => "recurrence/electricity_postpaid/internal#notify_stop"
  # internal
  post "/electricities/postpaid-transactions/pay" => "electricity_postpaids#pay"
  post "/electricities/postpaid-transactions/invoicing" => "electricity_postpaids#invoicing"
  post "/electricities/postpaid-transactions/confirm" => "electricity_postpaids#confirm"
  scope '_internal', module: :internal do
    post "/electricities/postpaid-inquiries" => "electricity_postpaids#inquiries"
    post "/electricities/postpaid-transactions" => "electricity_postpaids#create"
    get  "/electricities/postpaid-transactions/:id" => "electricity_postpaids#show"
    post "/electricities/postpaid-transactions/resend-email" => "electricity_postpaids#resend_email"
    patch "/electricities/postpaid-transactions/:id/status" => "electricity_postpaids#status"

    #partners
    get "/electricities/postpaid-partners" => "electricity_postpaids#get_partners"
  end
  # exclusive
  scope '_exclusive', module: :exclusive do
    get "/electricities/postpaid-partners" => "electricity_postpaid_partner#list"
    get "/electricities/postpaid-partners/balances" => "electricity_postpaid_partner#get_balance"
    patch "/electricities/postpaid-partners/balances" => "electricity_postpaid_partner#modify_balance"
    patch "/electricities/postpaid-partners/:id" => "electricity_postpaid_partner#update"

    # transactions
    get "/electricities/postpaid-transactions" => "transaction/electricity_postpaid#show_by_customer_number"
    get "/electricities/postpaid-transactions/:id" => "transaction/electricity_postpaid#show"

    # general circuit breakers
    get "/electricities/postpaid-general-circuit-breakers" => "general_circuit_breaker#show"
  end
  # partner
  scope '_partners', module: :partner do
    post '/electricities/postpaid-partners/ayoconnect/callbacks' => 'electricity_postpaid/ayoconnect#callbacks'
  end

  # new bpjs
  # public
  post "/bpjs-kesehatan/inquiries" => "bpjs_kesehatan#inquiries"
  get "/bpjs-kesehatan/inquiries/quickpays" => "bpjs_kesehatan_quickpays#index"
  delete "/bpjs-kesehatan/inquiries/quickpays" => "bpjs_kesehatan_quickpays#delete"
  post "/bpjs-kesehatan/transactions" => "bpjs_kesehatan#create"
  get  "/bpjs-kesehatan/transactions/:id" => "bpjs_kesehatan#show"
  get  "/bpjs-kesehatan/transactions/:id/receipt" => "bpjs_kesehatan#get_receipt"
  # recurrence
  post "/bpjs-kesehatan/recurrences/template-details" => "recurrence/bpjs_kesehatan/template_details#create"
  get  "/bpjs-kesehatan/recurrences/template-details/:id" => "recurrence/bpjs_kesehatan/template_details#show"
  post "_internal/bpjs-kesehatan/recurrences" => "recurrence/bpjs_kesehatan/internal#create"
  post "_internal/bpjs-kesehatan/recurrences/notify-balance" => "recurrence/bpjs_kesehatan/internal#notify_balance"
  post "_internal/bpjs-kesehatan/recurrences/notify-stop" => "recurrence/bpjs_kesehatan/internal#notify_stop"
  # internal
  post "/bpjs-kesehatan/transactions/pay" => "bpjs_kesehatan#pay"
  post "/bpjs-kesehatan/transactions/invoicing" => "bpjs_kesehatan#invoicing"
  post "/bpjs-kesehatan/transactions/confirm" => "bpjs_kesehatan#confirm"
  scope '_internal', module: :internal do
    get "bpjs-kesehatan/transactions/:id" => "bpjs_kesehatan#show"
    patch "bpjs-kesehatan/transactions/:id/status" => "bpjs_kesehatan#status"
  end
  # exclusive
  scope '_exclusive', module: :exclusive do
    get "/bpjs-kesehatan/partners" => "bpjs_kesehatan_partner#list"
    get "/bpjs-kesehatan/partners/:id" => "bpjs_kesehatan_partner#show"
    put "/bpjs-kesehatan/partners" => "bpjs_kesehatan_partner#update"

    # transactions
    get "/bpjs-kesehatan/transactions" => "transaction/bpjs_kesehatan#show_by_customer_number"
    get "/bpjs-kesehatan/transactions/:id" => "transaction/bpjs_kesehatan#show"
    post "/bpjs-kesehatan/transactions/confirm" => "transaction/bpjs_kesehatan#confirm"
  end

  # pdam
  # public
  get  "/pdam/operators" => "pdam#operators"
  post "/pdam/inquiries" => "pdam#inquiries"
  get "/pdam/inquiries/quickpays" => "pdam_quickpays#index"
  delete "/pdam/inquiries/quickpays" => "pdam_quickpays#delete"
  post "/pdam/transactions" => "pdam#create"
  get  "/pdam/transactions/:id" => "pdam#show"
  get  "/pdam/transaction-configs" => "pdam#has_transacted"
  # recurrence
  post "/pdam/recurrences/template-details" => "recurrence/pdam/template_details#create"
  get  "/pdam/recurrences/template-details/:id" => "recurrence/pdam/template_details#show"
  post "_internal/pdam/recurrences" => "recurrence/pdam/internal#create"
  post "_internal/pdam/recurrences/notify-balance" => "recurrence/pdam/internal#notify_balance"
  post "_internal/pdam/recurrences/notify-stop" => "recurrence/pdam/internal#notify_stop"
  # internal
  post "/pdam/transactions/pay" => "pdam#pay"
  post "/pdam/transactions/invoicing" => "pdam#invoicing"
  post "/pdam/transactions/confirm" => "pdam#confirm"
  scope '_internal', module: :internal do
    get "/pdam/transactions/:id" => "pdam#show"
    patch "/pdam/transactions/:id/status" => "pdam#status"
    post "/pdam/inquiries" => "pdam#inquiries"
    post "/pdam/transactions/" => "pdam#create"
    get "/pdam/transactions/:id/commissions" => "pdam#commission"
  end
  # exclusive
  scope '_exclusive', module: :exclusive do
    get     "/pdam/operators" => "pdam_operator#list"
    get     "/pdam/operators/:id" => "pdam_operator#show"
    post    "/pdam/operators" => "pdam_operator#create"
    put     "/pdam/operators" => "pdam_operator#update"
    delete  "/pdam/operators/:id" => "pdam_operator#delete"

    # transactions (from admin side)
    post    "/pdam/admin/transactions/confirm" => "transaction/pdam#confirm"
    get     "/pdam/transactions" => "transaction/pdam#show_by_customer_number"
    get     "/pdam/transactions/:id" => "transaction/pdam#show"

    # autoswitch
    get     "/pdam/admin/autoswitches/groups"            => "pdam/admin/autoswitch/group#index"
    get     "/pdam/admin/autoswitches/groups/:id"        => "pdam/admin/autoswitch/group#show"
    post    "/pdam/admin/autoswitches/groups"            => "pdam/admin/autoswitch/group#create"
    delete  "/pdam/admin/autoswitches/groups/:id"        => "pdam/admin/autoswitch/group#delete"
    patch   "/pdam/admin/autoswitches/groups/:id"        => "pdam/admin/autoswitch/group#update"
    patch   "/pdam/admin/autoswitches/groups/:id/status" => "pdam/admin/autoswitch/group#status"

    # autoswitch group member
    post    "/pdam/admin/autoswitches/groups/:group_id/members"            => "pdam/admin/autoswitch/group_member#create"
    delete  "/pdam/admin/autoswitches/groups/:group_id/members/:id"        => "pdam/admin/autoswitch/group_member#delete"
    patch   "/pdam/admin/autoswitches/groups/:group_id/members/:id/status" => "pdam/admin/autoswitch/group_member#status"

    # autoswitch group member setting
    get     "/pdam/admin/autoswitches/members/:member_id/settings"     => "pdam/admin/autoswitch/group_member_setting#index"
    post    "/pdam/admin/autoswitches/members/:member_id/settings"     => "pdam/admin/autoswitch/group_member_setting#create"
    patch   "/pdam/admin/autoswitches/members/:member_id/settings/:id" => "pdam/admin/autoswitch/group_member_setting#update"

    # reprocessing transaction
    get     "/pdam/admin/reprocessing-jobs" => "pdam/admin/reprocessing_job/job#index"
    get     "/pdam/admin/reprocessing-jobs/:job_id/transactions" => "pdam/admin/reprocessing_job/transaction#index"
    post    "/pdam/admin/reprocessing-jobs/transactions" => "pdam/admin/reprocessing_job/transaction#reprocess"

    # commission
    get     "/pdam/operators/:operator_id/commissions" => "pdam_operator_commission_setting#show"
    post    "/pdam/operators/:operator_id/commissions" => "pdam_operator_commission_setting#create"
    put     "/pdam/operators/:operator_id/commissions" => "pdam_operator_commission_setting#update"
  end

  # phone credit postpaid
  # public
  post "/phone-credits/postpaid-inquiries" => "phone_credit#inquiries"
  get "/phone-credits/postpaid-inquiries/quickpays" => "phone_credit_quickpays#index"
  delete "/phone-credits/postpaid-inquiries/quickpays" => "phone_credit_quickpays#delete"
  post "/phone-credits/postpaid-transactions" => "phone_credit#create"
  get  "/phone-credits/postpaid-transactions/:id" => "phone_credit#show"
  # recurrence
  post "/phone-credits/postpaid-recurrences/template-details" => "recurrence/phone_credit_postpaid/public#create"
  get  "/phone-credits/postpaid-recurrences/template-details/:id" => "recurrence/phone_credit_postpaid/public#show"
  post "_internal/phone-credits/postpaid-recurrences" => "recurrence/phone_credit_postpaid/internal#create"
  post "_internal/phone-credits/postpaid-recurrences/notify-balance" => "recurrence/phone_credit_postpaid/internal#notify_balance"
  post "_internal/phone-credits/postpaid-recurrences/notify-stop" => "recurrence/phone_credit_postpaid/internal#notify_stop"
  # internal
  post "/phone-credits/postpaid-transactions/pay" => "phone_credit#pay"
  post "/phone-credits/postpaid-transactions/invoicing" => "phone_credit#invoicing"
  post "/phone-credits/postpaid-transactions/confirm" => "phone_credit#confirm"
  scope '_internal', module: :internal do
    patch "/phone-credits/postpaid-transactions/:id/status" => "phone_credit#status"
  end
  # exclusive
  scope '_exclusive', module: :exclusive do
    get     "/phone-credits/providers" => "phone_credit_provider#list"
    get     "/phone-credits/providers/:id" => "phone_credit_provider#show"
    put     "/phone-credits/providers" => "phone_credit_provider#update"

    # transactions
    get "/phone-credits/postpaid-transactions/:id" => "transaction/phone_credit#show"
  end

  # credit-card-bills
  # public
  get "/credit-card-bills/billers" => "credit_card_bill#billers"
  post "/credit-card-bills/inquiries" => "credit_card_bill#inquiries"
  post "/credit-card-bills/transactions" => "credit_card_bill#create"
  get "/credit-card-bills/transactions/:id" => "credit_card_bill#show"
  # internal
  scope '_internal', module: :internal do
    post    "/credit-card-bills/inquiries" => "credit_card_bill#inquiries"
    post    "/credit-card-bills/pnl-callback" => "credit_card_bill#pnl_callback"
    get     "/credit-card-bills/transactions/:id" => "credit_card_bill#show"
    post    "/credit-card-bills/transactions/" => "credit_card_bill#create"
    post    "/credit-card-bills/transactions/pay" => "credit_card_bill#pay"
    post    "/credit-card-bills/transactions/invoicing" => "credit_card_bill#invoicing"
    post    "/credit-card-bills/transactions/confirm" => "credit_card_bill#confirm"
    patch   "/credit-card-bills/transactions/:id/status" => "credit_card_bill#status"
  end
  # exclusive
  scope '_exclusive', module: :exclusive do
    # biller
    get "/credit-card-bills/billers" => "credit_card_biller#list"
    get "/credit-card-bills/billers/:id" => "credit_card_biller#show"
    get "/credit-card-bills/billers/:id/partners" => "credit_card_biller#show_biller_partners"
    post "/credit-card-bills/billers" => "credit_card_biller#create"
    put "/credit-card-bills/billers/:id" => "credit_card_biller#update"
    delete "/credit-card-bills/billers/:id" => "credit_card_biller#delete"

    # partner
    get "/credit-card-bills/partners" => "credit_card_bill_partner#show_partners"
    get "/credit-card-bills/billers/:biller_id/partners" => "credit_card_bill_partner#show_biller_partners"
    post "/credit-card-bills/billers/:biller_id/partners" => "credit_card_bill_partner#create"
    put "/credit-card-bills/billers/:biller_id/partners/:id" => "credit_card_bill_partner#update"
    delete "/credit-card-bills/billers/:biller_id/partners/:id" => "credit_card_bill_partner#delete"

    # transactions
    get "/credit-card-bills/transactions/:id" => "transaction/credit_card_bill#show"
    post "/credit-card-bills/transactions/confirm" => "transaction/credit_card_bill#confirm"
  end
  # partner
  scope '_partners', module: :partner do
    post '/credit-card-bills/thor/callbacks' => 'credit-card-bills/thor/callbacks'
  end

  # vehicle tax
  post "/vehicle-taxes/bills" => "vehicle_taxes#bill_generates"
  get "/vehicle-taxes/transactions" => "vehicle_taxes#index"
  post "/vehicle-taxes/transactions" => "vehicle_taxes#create"
  get  "/vehicle-taxes/transactions/:id" => "vehicle_taxes#show"
  post "/vehicle-taxes/transactions/pay" => "vehicle_taxes#pay"
  post "/vehicle-taxes/transactions/invoicing" => "vehicle_taxes#invoicing"
  post "/vehicle-taxes/transactions/confirm" => "vehicle_taxes#confirm"

  # mws callback - background jobs
  scope '_internal', module: :internal do
    post '/background-jobs/credit-card-bill/transactions/create' => 'background_jobs/credit_card_bill#transaction_create'
    post '/background-jobs/postpaid/transactions/create' => 'background_jobs/postpaid#transaction_create'
    post '/background-jobs/postpaid/transactions/confirm' => 'background_jobs/postpaid#transaction_confirm'
    post '/background-jobs/postpaid/transactions/send-email' => 'background_jobs/postpaid#transaction_send_email'
    post '/background-jobs/postpaid/transactions/update-remote' => 'background_jobs/postpaid#transaction_update_remote'
    post '/background-jobs/postpaid/transactions/callback/sepulsa' => 'background_jobs/postpaid#transaction_callback_sepulsa'
    post '/background-jobs/postpaid/transactions/sievex-predict' => 'background_jobs/postpaid#transaction_sievex_predict'
    post '/background-jobs/postpaid/users/user-deleted' => 'background_jobs/postpaid#user_deleted'
  end

  # bpjs ketenagakerjaan
  post '/bpjs-ketenagakerjaan/inquiries' => 'bpjs_ketenagakerjaan#inquiries'
  post '/bpjs-ketenagakerjaan/transactions' => 'bpjs_ketenagakerjaan#create'
  get  "/bpjs-ketenagakerjaan/transactions/:id" => "bpjs_ketenagakerjaan#show"
  get  "/bpjs-ketenagakerjaan/transactions/:id/receipt" => "bpjs_ketenagakerjaan#get_receipt"

  # exclusive
  scope '_exclusive', module: :exclusive do
    #transactions
    get '/bpjs-ketenagakerjaan/transactions/:id' => 'transaction/bpjs_ketenagakerjaan#show'
    post '/bpjs-ketenagakerjaan/transactions/confirm' => 'transaction/bpjs_ketenagakerjaan#confirm'
  end

  #internal
  scope '_internal', module: :internal do
    post '/bpjs-ketenagakerjaan/transactions/pay' => 'bpjs_ketenagakerjaan#pay'
    post '/bpjs-ketenagakerjaan/transactions/confirm' => 'bpjs_ketenagakerjaan#confirm'
    post '/bpjs-ketenagakerjaan/transactions/invoicing' => 'bpjs_ketenagakerjaan#invoicing'
    patch '/bpjs-ketenagakerjaan/transactions/:id/status' => 'bpjs_ketenagakerjaan#status'
    get '/bpjs-ketenagakerjaan/transactions/:id' => 'bpjs_ketenagakerjaan#show'
  end
end
