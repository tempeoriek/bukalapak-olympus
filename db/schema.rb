# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2023_12_19_081208) do

  create_table "bills", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.date "bill_period"
    t.date "due_date"
    t.integer "penalty_fee"
    t.bigint "amount"
    t.string "previous_meter"
    t.string "current_meter"
    t.integer "postpaid_transaction_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["postpaid_transaction_id"], name: "index_bills_on_postpaid_transaction_id"
  end

  create_table "bpjs_kesehatan_family_members", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "member_number"
    t.string "name"
    t.integer "premium"
    t.integer "balance"
    t.integer "bpjs_kesehatan_transaction_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bpjs_kesehatan_transaction_id"], name: "index_bpjs_kesehatan_family_members_on_bpjs_kesehatan_id"
  end

  create_table "bpjs_kesehatan_partners", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.integer "partner_admin_charge"
    t.integer "bukalapak_admin_charge"
    t.integer "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "revenue", limit: 3, default: 0, unsigned: true
  end

  create_table "bpjs_kesehatan_recurrence_template_details", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "customer_number"
    t.string "customer_name"
    t.string "phone_number"
    t.integer "family_member_count"
    t.bigint "buyer_id"
    t.integer "recursive_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recursive_id"], name: "bpjs_recurrence_template_on_recursive_id"
  end

  create_table "bpjs_kesehatan_transactions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "buyer_id"
    t.bigint "invoice_id"
    t.bigint "remote_transaction_id"
    t.string "partner_transaction_id"
    t.integer "partner"
    t.string "customer_number"
    t.string "customer_name"
    t.integer "family_member_count"
    t.string "branch_name"
    t.integer "amount"
    t.integer "admin_charge"
    t.string "payment_period"
    t.string "paid_until"
    t.integer "state"
    t.datetime "processed_at"
    t.datetime "succeeded_at"
    t.datetime "failed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "reference_number"
    t.string "info"
    t.string "phone_number", default: ""
    t.bigint "template_detail_id"
    t.integer "transaction_type"
    t.datetime "paid_at"
    t.integer "bukalapak_admin_charge"
    t.integer "partner_admin_charge"
    t.datetime "partner_succeeded_at"
    t.datetime "partner_failed_at"
    t.datetime "cancelled_at"
    t.datetime "expired_at"
    t.integer "revenue", limit: 3, default: 0, unsigned: true
    t.datetime "revenue_at"
    t.index ["buyer_id", "state", "succeeded_at"], name: "index_bpjs_kesehatan_transactions_on_quickpay_list"
    t.index ["buyer_id"], name: "index_bpjs_kesehatan_transactions_on_buyer_id"
    t.index ["created_at"], name: "index_bpjs_kesehatan_transactions_on_created_at"
    t.index ["customer_number", "created_at"], name: "index_cust_no_bpjs_kes_transaction"
    t.index ["paid_at"], name: "index_bpjs_kesehatan_transaction_on_paid_at"
    t.index ["partner"], name: "index_bpjs_kesehatan_transactions_on_partner"
    t.index ["remote_transaction_id"], name: "index_bpjs_kesehatan_transactions_on_remote_transaction_id"
    t.index ["revenue_at"], name: "index_bpjs_kesehatan_transactions_on_revenue_at"
    t.index ["state"], name: "index_bpjs_kesehatan_transactions_on_state"
    t.index ["updated_at"], name: "index_bpjs_kesehatan_transactions_on_updated_at"
  end

  create_table "bpjs_ketenagakerjaan_bills", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "jkk", default: 0, unsigned: true
    t.integer "jkm", default: 0, unsigned: true
    t.integer "jht", default: 0, unsigned: true
    t.integer "jkp", default: 0, unsigned: true
    t.integer "jp", default: 0, unsigned: true
    t.integer "amount", default: 0, unsigned: true
    t.bigint "bpjs_ketenagakerjaan_transaction_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "bpjs_ketenagakerjaan_partners", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.integer "partner_admin_charge", default: 0, unsigned: true
    t.integer "bukalapak_admin_charge", default: 0, unsigned: true
    t.integer "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "revenue"
  end

  create_table "bpjs_ketenagakerjaan_transactions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "buyer_id"
    t.bigint "invoice_id"
    t.bigint "remote_transaction_id"
    t.string "partner_transaction_id"
    t.integer "partner"
    t.string "customer_number"
    t.string "customer_name"
    t.string "branch_name"
    t.integer "admin_charge"
    t.string "payment_period"
    t.date "start_bill_period"
    t.date "end_bill_period"
    t.integer "state"
    t.integer "amount", default: 0, unsigned: true
    t.datetime "processed_at"
    t.datetime "succeeded_at"
    t.datetime "failed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "paid_at"
    t.datetime "partner_succeeded_at"
    t.datetime "partner_failed_at"
    t.datetime "cancelled_at"
    t.datetime "expired_at"
    t.string "reference_number"
    t.string "info"
    t.string "phone_number", default: ""
    t.bigint "template_detail_id"
    t.integer "transaction_type"
    t.integer "bukalapak_admin_charge"
    t.integer "partner_admin_charge"
    t.integer "revenue", limit: 3, default: 0, unsigned: true
    t.datetime "revenue_at"
    t.integer "bpjs_tk_type"
    t.string "division"
    t.string "npp"
    t.string "bill_code"
    t.boolean "unpaid_bills", default: false
    t.index ["buyer_id", "state", "succeeded_at"], name: "index_bpjstk_transactions_on_buyer_id_and_state_and_succeeded_at"
    t.index ["buyer_id"], name: "index_bpjs_ketenagakerjaan_transactions_on_buyer_id"
    t.index ["created_at"], name: "index_bpjs_ketenagakerjaan_transactions_on_created_at"
    t.index ["paid_at"], name: "index_bpjs_ketenagakerjaan_transactions_on_paid_at"
    t.index ["partner"], name: "index_bpjs_ketenagakerjaan_transactions_on_partner"
    t.index ["remote_transaction_id"], name: "index_bpjs_ketenagakerjaan_transactions_on_remote_transaction_id"
    t.index ["revenue_at"], name: "index_bpjs_ketenagakerjaan_transactions_on_revenue_at"
    t.index ["state"], name: "index_bpjs_ketenagakerjaan_transactions_on_state"
    t.index ["succeeded_at"], name: "index_bpjs_ketenagakerjaan_transactions_on_succeeded_at"
    t.index ["updated_at"], name: "index_bpjs_ketenagakerjaan_transactions_on_updated_at"
  end

  create_table "brand_partners", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "parameterized_name"
    t.integer "user_id"
    t.string "username"
    t.string "brand_name"
    t.text "brand_description"
    t.text "page_description"
    t.string "url"
    t.string "logo_url"
    t.string "background_desktop_url"
    t.string "background_mobile_url"
    t.boolean "promoted"
    t.integer "promoted_product_counter"
    t.boolean "local_brand"
    t.datetime "brand_created_at"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parameterized_name"], name: "index_brand_partners_on_parameterized_name", unique: true
    t.index ["parameterized_name"], name: "index_parameterized"
    t.index ["user_id"], name: "index_userid"
    t.index ["username"], name: "index_username"
  end

  create_table "credit_card_bill_partners", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.text "terms_and_conditions"
    t.string "biller_code", limit: 50
    t.integer "bukalapak_admin_charge"
    t.integer "partner_admin_charge"
    t.integer "credit_card_biller_id"
    t.integer "state", limit: 1
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }
    t.integer "revenue", limit: 3, default: 0, unsigned: true
  end

  create_table "credit_card_bill_transactions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "buyer_id"
    t.string "customer_name"
    t.string "customer_number"
    t.date "statement_date"
    t.date "due_date"
    t.integer "amount"
    t.integer "minimum_payment"
    t.integer "bukalapak_admin_charge"
    t.integer "partner_admin_charge"
    t.integer "state"
    t.integer "transaction_type"
    t.integer "credit_card_biller_id"
    t.integer "credit_card_bill_partner_id"
    t.string "reference_number"
    t.string "token"
    t.string "card_data"
    t.string "partner_financial_journal_number"
    t.string "partner_journal_number"
    t.string "partner_transaction_id"
    t.bigint "remote_transaction_id"
    t.bigint "invoice_id"
    t.datetime "paid_at"
    t.datetime "processed_at"
    t.datetime "succeeded_at"
    t.datetime "failed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "response_code", limit: 1, unsigned: true
    t.datetime "cancelled_at"
    t.datetime "expired_at"
    t.datetime "partner_succeeded_at"
    t.datetime "partner_failed_at"
    t.integer "revenue", limit: 3, default: 0, unsigned: true
    t.datetime "revenue_at"
    t.index ["buyer_id"], name: "index_credit_card_bill_transactions_on_buyer_id"
    t.index ["created_at"], name: "index_credit_card_bill_transactions_on_created_at"
    t.index ["credit_card_bill_partner_id"], name: "index_credit_card_bill_transaction_on_partner_id"
    t.index ["credit_card_biller_id"], name: "index_credit_card_bill_transactions_on_credit_card_biller_id"
    t.index ["paid_at"], name: "index_credit_card_bill_transaction_on_paid_at"
    t.index ["partner_transaction_id"], name: "index_credit_card_bill_transactions_on_partner_transaction_id"
    t.index ["processed_at", "state"], name: "index_credit_card_bill_transactions_on_reconcile_list"
    t.index ["reference_number"], name: "index_credit_card_bill_transactions_on_reference_number"
    t.index ["remote_transaction_id"], name: "index_credit_card_bill_transactions_on_remote_transaction_id"
    t.index ["revenue_at"], name: "index_credit_card_bill_transactions_on_revenue_at"
    t.index ["state"], name: "index_credit_card_bill_transactions_on_state"
    t.index ["updated_at"], name: "index_credit_card_bill_transactions_on_updated_at"
  end

  create_table "credit_card_billers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.string "code"
    t.string "image_url"
    t.text "terms_and_conditions"
    t.integer "bukalapak_admin_charge"
    t.integer "partner_admin_charge"
    t.integer "active", default: 0
    t.integer "credit_card_bill_partner_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "donation_campaign_details", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "donation_campaign_id"
    t.string "image_url"
    t.string "packet_name"
    t.integer "nominal"
    t.integer "quota", limit: 2
    t.boolean "deleted", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted", "donation_campaign_id"], name: "index_deleted_campaignid"
  end

  create_table "donation_campaign_transaction_details", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "donation_campaign_transaction_id"
    t.integer "donation_campaign_detail_id"
    t.integer "donation_campaign_id"
    t.integer "qty"
    t.integer "nominal_per_qty"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["donation_campaign_detail_id"], name: "index_donation_campaign_detail"
    t.index ["donation_campaign_id"], name: "index_donation_campaign"
    t.index ["donation_campaign_transaction_id"], name: "index_donation_campaign_transaction"
  end

  create_table "donation_campaign_transactions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "donation_campaign_id"
    t.integer "donor_id"
    t.bigint "invoice_id"
    t.bigint "remote_id"
    t.integer "remote_partner_id"
    t.integer "state", limit: 1
    t.decimal "nominal", precision: 15, scale: 2
    t.integer "extra_amount", default: 0
    t.boolean "anonymous", default: true, null: false
    t.decimal "nominal_fee", precision: 12, scale: 2
    t.string "source", default: "donation_adhoc"
    t.datetime "processed_at"
    t.datetime "succeeded_at"
    t.datetime "failed_at"
    t.datetime "expired_at"
    t.integer "updater"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["donation_campaign_id"], name: "index_donation_campaign_id"
    t.index ["donor_id"], name: "index_donorid"
    t.index ["invoice_id"], name: "index_invoiceid"
    t.index ["remote_id"], name: "index_remoteid"
  end

  create_table "donation_campaigns", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "foundation_id"
    t.string "title", limit: 50, null: false
    t.string "short_description"
    t.text "description", null: false
    t.string "slug"
    t.string "image_url", null: false
    t.string "story_image_url"
    t.string "thumbnail_url"
    t.integer "campaign_type", limit: 1, null: false
    t.boolean "banner_showed", default: true
    t.string "url"
    t.string "location_text"
    t.datetime "campaign_due"
    t.string "other_donation_url"
    t.string "brand_parameterized_name"
    t.string "banners_url", limit: 1000
    t.datetime "start_time"
    t.datetime "end_time"
    t.decimal "donation_min", precision: 12, scale: 2
    t.decimal "donation_max", precision: 15, scale: 2
    t.integer "bl_total_donor"
    t.integer "all_total_donor"
    t.decimal "target_expense", precision: 15, scale: 2
    t.decimal "bl_collected_expense", precision: 15, scale: 2
    t.decimal "all_collected_expense", precision: 15, scale: 2
    t.string "available_nominals", limit: 50
    t.integer "extra_percentage", default: 0
    t.integer "extra_maximum_amount", default: 0
    t.integer "extra_budget", default: 0
    t.integer "deduction_percentage", default: 0
    t.integer "flow_type", limit: 1, default: 1, null: false
    t.boolean "partnering", default: false, null: false
    t.integer "partner_id"
    t.boolean "keep_update", default: true, null: false
    t.datetime "partner_updated_at"
    t.integer "sort_order", default: 99, null: false
    t.integer "custom_sort_order", default: 99
    t.boolean "visibility", default: true, null: false
    t.boolean "active", default: true, null: false
    t.integer "updater_id"
    t.boolean "deleted", default: false, null: false
    t.string "partner", limit: 25
    t.integer "category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["custom_sort_order"], name: "custom_sort_order"
    t.index ["deleted", "active", "slug"], name: "index_deleted_active_slug"
    t.index ["deleted", "active", "visibility", "foundation_id", "sort_order"], name: "index_deleted_active_visibility_foundation_sortorder"
    t.index ["end_time"], name: "index_end_time"
    t.index ["slug"], name: "index_donation_campaigns_on_slug", unique: true
    t.index ["start_time"], name: "index_start_time"
  end

  create_table "donation_foundations", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "user_id"
    t.string "parameterized_name"
    t.integer "total_campaign", limit: 2
    t.integer "sort_order", limit: 2
    t.boolean "active", default: true, null: false
    t.boolean "deleted", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted", "active", "sort_order"], name: "index_deleted_active_sortorder"
  end

  create_table "donation_services", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "foundation_id"
    t.string "service_code", limit: 25, null: false
    t.string "service_name", limit: 25, null: false
    t.string "service_image", null: false
    t.string "service_url", null: false
    t.integer "sort_order", default: 99, null: false
    t.boolean "active", default: true, null: false
    t.boolean "deleted", default: false, null: false
    t.boolean "is_master", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted", "active", "sort_order"], name: "index_deleted_active_sortorder"
    t.index ["foundation_id"], name: "index_donation_services_on_foundation_id"
    t.index ["is_master"], name: "index_donation_services_on_is_master"
  end

  create_table "donation_window_products", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "donation_window_id"
    t.string "product_id"
    t.integer "sort_order", limit: 2
    t.boolean "deleted", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted", "donation_window_id", "sort_order"], name: "index_deleted_donationwindow_sortorder"
  end

  create_table "donation_windows", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "label", limit: 25, null: false
    t.string "background_image_url", null: false
    t.string "banner_url"
    t.integer "sort_order", default: 99, null: false
    t.boolean "active", default: true, null: false
    t.boolean "deleted", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted", "active", "sort_order"], name: "index_deleted_active_sortorder"
  end

  create_table "electricity_postpaid_mass_bills", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "mass_bill_id", limit: 36
    t.bigint "postpaid_transaction_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["mass_bill_id", "postpaid_transaction_id"], name: "index_elec_postpaid_mass_bill_unique", unique: true
    t.index ["postpaid_transaction_id"], name: "index_electricity_postpaid_mass_bills_on_postpaid_transaction_id", unique: true
  end

  create_table "electricity_postpaid_partners", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.integer "partner_admin_charge"
    t.integer "bukalapak_admin_charge"
    t.integer "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "bukalapak_commission", limit: 3, default: 0, unsigned: true
    t.integer "partner_type"
    t.string "code"
  end

  create_table "electricity_postpaid_partners_balances", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "electricity_postpaid_partners_id"
    t.bigint "amount"
    t.bigint "threshold"
    t.integer "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["electricity_postpaid_partners_id"], name: "electricity_postpaid_partners_balances_on_partners_id"
  end

  create_table "electricity_postpaid_recurrence_template_details", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "customer_number"
    t.string "customer_name"
    t.string "segmentation"
    t.integer "power"
    t.bigint "buyer_id"
    t.integer "recursive_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recursive_id"], name: "electricity_recurrence_template_on_recursive_id"
  end

  create_table "foundation_products", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "foundation_id"
    t.string "product_id"
    t.boolean "active", default: true, null: false
    t.boolean "deleted", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["foundation_id"], name: "index_foundation_products_on_foundation_id"
  end

  create_table "foundations", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "user_id"
    t.string "name"
    t.string "parameterized_name"
    t.string "slug"
    t.string "banner_url_desktop"
    t.string "banner_url_app"
    t.string "icon_url"
    t.text "description"
    t.string "address"
    t.string "website_url"
    t.string "facebook_url"
    t.string "twitter_url"
    t.string "instagram_url"
    t.integer "active_event_id"
    t.integer "event_id"
    t.integer "updater_id"
    t.integer "sort_order", default: 99, null: false
    t.boolean "active", default: true, null: false
    t.boolean "deleted", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "keystores", id: :bigint, unsigned: true, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "key"
    t.string "value"
    t.datetime "expiration_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_keystores_on_created_at"
    t.index ["key"], name: "index_keystores_on_key"
    t.index ["updated_at"], name: "index_keystores_on_updated_at"
  end

  create_table "multifinance_billers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.string "code"
    t.string "image_url"
    t.integer "bukalapak_admin_charge"
    t.integer "partner_admin_charge"
    t.integer "active", default: 0
    t.integer "partner", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.time "cutoff_start"
    t.time "cutoff_end"
  end

  create_table "multifinance_transactions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "buyer_id"
    t.string "customer_name"
    t.string "customer_number"
    t.string "item_name"
    t.string "license_number"
    t.string "reference_number"
    t.date "due_date"
    t.string "installment_period"
    t.integer "partner"
    t.integer "amount"
    t.integer "penalty_fee"
    t.integer "bukalapak_admin_charge"
    t.integer "partner_admin_charge"
    t.integer "state"
    t.integer "multifinance_biller_id"
    t.string "partner_transaction_id"
    t.integer "remote_transaction_id"
    t.integer "invoice_id"
    t.datetime "paid_at"
    t.datetime "processed_at"
    t.datetime "succeeded_at"
    t.datetime "failed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["buyer_id", "state", "succeeded_at"], name: "index_multifinance_transactions_on_quickpay_list"
    t.index ["buyer_id"], name: "index_multifinance_transactions_on_buyer_id"
    t.index ["created_at"], name: "index_multifinance_transactions_on_created_at"
    t.index ["multifinance_biller_id"], name: "index_multifinance_transactions_on_multifinance_biller_id"
    t.index ["partner"], name: "index_multifinance_transactions_on_partner"
    t.index ["remote_transaction_id"], name: "index_multifinance_transactions_on_remote_transaction_id"
    t.index ["state"], name: "index_multifinance_transactions_on_state"
    t.index ["updated_at"], name: "index_multifinance_transactions_on_updated_at"
  end

  create_table "pdam_autoswitch_group_member_settings", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "autoswitch_group_member_id"
    t.integer "threshold_value"
    t.integer "threshold_min_trx"
    t.integer "threshold_period_in_seconds"
    t.integer "threshold_type"
    t.integer "threshold_state", limit: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "pdam_autoswitch_group_members", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "autoswitch_group_id"
    t.integer "operator_id"
    t.integer "state", limit: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["autoswitch_group_id"], name: "index_pdam_autoswitch_group_members_on_autoswitch_group_id"
    t.index ["operator_id"], name: "index_pdam_autoswitch_group_members_on_operator_id"
    t.index ["state"], name: "index_pdam_autoswitch_group_members_on_state"
  end

  create_table "pdam_autoswitch_groups", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.integer "state", limit: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_pdam_autoswitch_groups_on_name"
    t.index ["state"], name: "index_pdam_autoswitch_groups_on_state"
  end

  create_table "pdam_bills", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.date "bill_period"
    t.integer "penalty_fee"
    t.integer "amount"
    t.string "cubication"
    t.integer "pdam_transaction_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "tariff"
    t.integer "usage"
    t.index ["pdam_transaction_id"], name: "index_pdam_bills_on_pdam_transaction_id"
  end

  create_table "pdam_operator_commission_settings", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "value"
    t.integer "min_transaction_value"
    t.integer "max_transaction_value"
    t.bigint "pdam_operator_id"
    t.integer "state", limit: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pdam_operator_id"], name: "pdam_operator_commission_settings_pdam_operator_idx"
  end

  create_table "pdam_operators", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "code"
    t.string "name"
    t.string "group"
    t.string "image_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "active"
    t.integer "partner", default: 0
    t.integer "bukalapak_admin_charge", default: 0
    t.integer "partner_admin_charge", default: 0
    t.integer "bill_day", limit: 1, unsigned: true
    t.integer "due_day", limit: 1, unsigned: true
    t.text "terms_and_conditions"
    t.integer "revenue", limit: 3, default: 0, unsigned: true
    t.integer "have_issue", default: 0
    t.boolean "update_selling_price", default: false
    t.index ["active"], name: "index_pdam_operators_on_active"
  end

  create_table "pdam_recurrence_template_details", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "customer_number"
    t.string "customer_name"
    t.integer "operator_id"
    t.bigint "buyer_id"
    t.integer "recursive_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recursive_id"], name: "pdam_recurrence_template_on_recursive_id"
  end

  create_table "pdam_transactions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "buyer_id"
    t.string "customer_name"
    t.string "customer_number"
    t.date "start_bill_period"
    t.date "end_bill_period"
    t.integer "amount"
    t.integer "penalty_fee"
    t.integer "bukalapak_admin_charge"
    t.integer "partner_admin_charge"
    t.integer "state"
    t.integer "partner"
    t.integer "pdam_operator_id"
    t.string "partner_transaction_id"
    t.bigint "remote_transaction_id"
    t.bigint "invoice_id"
    t.datetime "processed_at"
    t.datetime "succeeded_at"
    t.datetime "failed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "address"
    t.bigint "template_detail_id"
    t.integer "transaction_type"
    t.datetime "paid_at"
    t.datetime "partner_succeeded_at"
    t.datetime "partner_failed_at"
    t.datetime "cancelled_at"
    t.datetime "expired_at"
    t.integer "revenue", limit: 3, default: 0, unsigned: true
    t.datetime "revenue_at"
    t.string "reference_number"
    t.string "stand_meter"
    t.integer "retribution", default: 0
    t.integer "segel", default: 0
    t.json "details"
    t.index ["buyer_id", "state", "succeeded_at"], name: "index_pdam_transactions_on_quickpay_list"
    t.index ["buyer_id"], name: "index_pdam_transactions_on_buyer_id"
    t.index ["created_at"], name: "index_pdam_transactions_on_created_at"
    t.index ["customer_number", "created_at"], name: "index_cust_no_pdam_transaction"
    t.index ["paid_at"], name: "index_pdam_transaction_on_paid_at"
    t.index ["partner"], name: "index_pdam_transactions_on_partner"
    t.index ["pdam_operator_id"], name: "index_pdam_transactions_on_pdam_operator_id"
    t.index ["remote_transaction_id"], name: "index_pdam_transactions_on_remote_transaction_id"
    t.index ["revenue_at"], name: "index_pdam_transactions_on_revenue_at"
    t.index ["state"], name: "index_pdam_transactions_on_state"
    t.index ["updated_at"], name: "index_pdam_transactions_on_updated_at"
  end

  create_table "phone_credit_postpaid_recurrence_template_details", id: :bigint, unsigned: true, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "customer_number"
    t.string "customer_name"
    t.bigint "buyer_id"
    t.integer "recursive_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recursive_id"], name: "phone_credit_postpaid_template_on_recursive_id"
  end

  create_table "phone_credit_postpaid_transactions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "buyer_id"
    t.string "customer_name"
    t.string "phone_number"
    t.integer "reference_no"
    t.integer "outstanding_bill"
    t.date "start_bill_period"
    t.date "end_bill_period"
    t.integer "bill_amount"
    t.integer "partner_admin_charge"
    t.integer "bukalapak_admin_charge"
    t.integer "total_amount"
    t.integer "state"
    t.bigint "provider_id"
    t.string "partner_transaction_id"
    t.bigint "remote_transaction_id"
    t.bigint "invoice_id"
    t.datetime "processed_at"
    t.datetime "succeeded_at"
    t.datetime "failed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "partner"
    t.string "reference_number"
    t.integer "transaction_type"
    t.datetime "paid_at"
    t.bigint "template_detail_id", unsigned: true
    t.datetime "partner_succeeded_at"
    t.datetime "partner_failed_at"
    t.datetime "cancelled_at"
    t.datetime "expired_at"
    t.integer "bukalapak_commission", unsigned: true
    t.index ["buyer_id", "state", "succeeded_at"], name: "index_phone_credit_postpaid_transactions_on_quickpay_list"
    t.index ["buyer_id"], name: "index_phone_credit_postpaid_transactions_on_buyer_id"
    t.index ["created_at"], name: "index_phone_credit_postpaid_transactions_on_created_at"
    t.index ["paid_at"], name: "index_phone_credit_postpaid_transaction_on_paid_at"
    t.index ["provider_id"], name: "index_phone_credit_postpaid_transactions_on_provider_id"
    t.index ["remote_transaction_id"], name: "index_phone_credit_postpaid_on_remote_transcation_id"
    t.index ["state"], name: "index_phone_credit_postpaid_transactions_on_state"
    t.index ["updated_at"], name: "index_phone_credit_postpaid_transactions_on_updated_at"
  end

  create_table "phone_credit_providers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "provider"
    t.string "product_name"
    t.string "logo_url"
    t.string "partner_product_id"
    t.integer "partner"
    t.integer "partner_admin_charge"
    t.integer "bukalapak_admin_charge"
    t.integer "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "activated_at"
    t.datetime "inactivated_at"
    t.integer "bukalapak_commission", unsigned: true
    t.index ["active"], name: "index_phone_credit_providers_on_active"
    t.index ["created_at"], name: "index_phone_credit_providers_on_created_at"
    t.index ["updated_at"], name: "index_phone_credit_providers_on_updated_at"
  end

  create_table "postpaid_transactions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "buyer_id"
    t.string "customer_name"
    t.string "customer_number"
    t.integer "power"
    t.string "segmentation"
    t.string "stand_meter"
    t.integer "outstanding_bill"
    t.bigint "amount"
    t.integer "penalty_fee"
    t.integer "state"
    t.integer "partner"
    t.string "partner_transaction_id"
    t.bigint "remote_transaction_id"
    t.bigint "invoice_id"
    t.datetime "processed_at"
    t.datetime "succeeded_at"
    t.datetime "failed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "admin_charge"
    t.integer "unpaid_bill"
    t.string "reference_number"
    t.string "info_text"
    t.integer "bukalapak_admin_charge"
    t.integer "partner_admin_charge"
    t.bigint "template_detail_id"
    t.integer "transaction_type"
    t.datetime "paid_at"
    t.datetime "partner_succeeded_at"
    t.datetime "partner_failed_at"
    t.datetime "cancelled_at"
    t.datetime "expired_at"
    t.string "created_on_platform", limit: 20
    t.integer "created_on_version", unsigned: true
    t.integer "bukalapak_commission", limit: 3, default: 0, unsigned: true
    t.index ["buyer_id", "state", "succeeded_at"], name: "index_postpaid_transactions_on_quickpay_list"
    t.index ["buyer_id"], name: "index_postpaid_transactions_on_buyer_id"
    t.index ["created_at"], name: "index_postpaid_transactions_on_created_at"
    t.index ["created_on_platform", "created_on_version"], name: "index_postpaid_transactions_on_platform_and_version"
    t.index ["customer_number", "created_at"], name: "index_cust_no_postpaid_transaction"
    t.index ["paid_at"], name: "index_postpaid_transaction_on_paid_at"
    t.index ["partner"], name: "index_postpaid_transactions_on_partner"
    t.index ["remote_transaction_id"], name: "index_postpaid_transactions_on_remote_transaction_id"
    t.index ["state"], name: "index_postpaid_transactions_on_state"
    t.index ["updated_at"], name: "index_postpaid_transactions_on_updated_at"
  end

  create_table "provider_prefixes", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "prefix"
    t.bigint "provider_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_provider_prefixes_on_created_at"
    t.index ["updated_at"], name: "index_provider_prefixes_on_updated_at"
  end

  create_table "reprocessing_jobs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "job_type"
    t.datetime "stuck_transaction_date"
    t.integer "state"
    t.integer "triggered_by_user_id"
    t.string "triggered_by_user_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["state"], name: "index_reprocessing_jobs_on_state"
  end

  create_table "reprocessing_transaction_maps", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "job_id"
    t.bigint "transaction_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["job_id"], name: "index_reprocessing_transaction_maps_on_job_id"
    t.index ["transaction_id"], name: "index_reprocessing_transaction_maps_on_transaction_id"
  end

  create_table "sievex_action_logs", id: :bigint, unsigned: true, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "entity_id"
    t.integer "entity_type"
    t.string "actor"
    t.string "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_sievex_action_logs_on_created_at"
    t.index ["entity_id"], name: "index_sievex_action_logs_on_entity_id"
    t.index ["updated_at"], name: "index_sievex_action_logs_on_updated_at"
  end

  create_table "vehicle_tax_bills", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "code"
    t.bigint "buyer_id"
    t.integer "transaction_id", unsigned: true
    t.integer "amount"
    t.integer "fee"
    t.string "customer_number"
    t.string "customer_name"
    t.text "customer_address"
    t.string "engine_number"
    t.string "structure_number"
    t.string "license_plate"
    t.string "vehicle_brand"
    t.string "vehicle_model"
    t.string "vehicle_color"
    t.string "year_built"
    t.date "tax_expired_date"
    t.date "stnk_expired_date"
    t.integer "amount_bnn", default: 0
    t.integer "amount_pkb", default: 0
    t.integer "amount_swd", default: 0
    t.integer "penalty_bnn", default: 0
    t.integer "penalty_pkb", default: 0
    t.integer "penalty_swd", default: 0
    t.integer "fee_stnk", default: 0
    t.integer "fee_tnkb", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["buyer_id", "code", "transaction_id"], name: "index_vehicle_tax_bills_on_buyer_id_and_code_and_transaction_id"
    t.index ["code"], name: "index_vehicle_tax_bills_on_code"
    t.index ["transaction_id", "structure_number"], name: "index_vehicle_tax_bills_on_transaction_id_and_structure_number"
  end

  create_table "vehicle_tax_transactions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "buyer_id"
    t.bigint "invoice_id"
    t.bigint "remote_transaction_id"
    t.string "partner_transaction_id"
    t.string "bill_code"
    t.string "state"
    t.integer "amount"
    t.integer "admin_fee", default: 0
    t.integer "partner_fee", default: 0
    t.text "notes"
    t.string "ntb"
    t.datetime "processed_at"
    t.datetime "succeeded_at"
    t.datetime "failed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bill_code"], name: "index_vehicle_tax_transactions_on_bill_code"
    t.index ["buyer_id", "invoice_id"], name: "index_vehicle_tax_transactions_on_buyer_id_and_invoice_id"
    t.index ["invoice_id"], name: "index_vehicle_tax_transactions_on_invoice_id"
    t.index ["remote_transaction_id"], name: "index_vehicle_tax_transactions_on_remote_transaction_id"
  end

  create_table "zakat_campaigns", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "image_url", null: false
    t.string "title", null: false
    t.text "description"
    t.string "slug", null: false
    t.integer "foundation_id"
    t.boolean "active", default: true
    t.boolean "deleted", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active", "slug"], name: "index_zakat_campaigns_on_active_and_slug"
  end

  create_table "zakat_foundations", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.boolean "active", default: true
    t.timestamp "deactivated_at"
    t.string "image_url"
    t.string "available_types"
    t.bigint "wallet_user_id", default: 0
    t.datetime "fitrah_end_date", default: "2019-05-01 00:00:00"
    t.integer "sort_order", default: 99
    t.decimal "revenue_percentage", precision: 5, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_zakat_foundations_on_active"
  end

  create_table "zakat_notifications", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "user_id", unsigned: true
    t.integer "day", limit: 1, default: 0
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["day"], name: "index_zakat_notifications_on_day"
    t.index ["user_id"], name: "index_zakat_notifications_on_user_id"
  end

  create_table "zakat_transactions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "buyer_id", unsigned: true
    t.string "buyer_name"
    t.bigint "invoice_id", unsigned: true
    t.bigint "remote_id", unsigned: true
    t.integer "amount"
    t.integer "foundation_id"
    t.integer "partner"
    t.integer "state"
    t.string "created_on"
    t.string "notes"
    t.datetime "expire_time"
    t.datetime "succeeded_at"
    t.datetime "failed_at"
    t.datetime "revived_at"
    t.integer "kind", limit: 1, default: 0, unsigned: true
    t.integer "revenue", limit: 3, default: 0, unsigned: true
    t.datetime "revenue_at"
    t.datetime "paid_at"
    t.datetime "invoiced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["buyer_id"], name: "index_zakat_transactions_on_buyer_id"
    t.index ["created_at"], name: "index_zakat_transactions_on_created_at"
    t.index ["invoice_id"], name: "index_zakat_transactions_on_invoice_id"
    t.index ["remote_id"], name: "index_zakat_transactions_on_remote_id"
    t.index ["state"], name: "index_zakat_transactions_on_state"
    t.index ["updated_at"], name: "index_zakat_transactions_on_updated_at"
  end

end
