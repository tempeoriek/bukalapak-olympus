# frozen_string_literal: true
module Postpaid
  module Constant
    module Test
      BUKALAPAK_ADMIN_CHARGE = 600
      PARTNER_ADMIN_CHARGE = 900
      ADMIN_CHARGE = (BUKALAPAK_ADMIN_CHARGE + PARTNER_ADMIN_CHARGE)
    end

    DEFAULT_LIMIT = 10.freeze
    DEFAULT_OFFSET = 0.freeze

    BUKACONNECT = 'bukaconnect'

    # partner
    SEPULSA = 'sepulsa'
    DJI = 'dji'
    DJI_PDAM_TO = 'dji-pdam-to'
    DJI_BPJS = 'dji-bpjs'
    BUKOPIN = 'bukopin'
    ADINS = 'adins'
    BNI = 'bni'
    PNL = 'pnl'
    VISA = 'visa'
    AYOCONNECT = 'ayoconnect'
    TEKTAYA = 'tektaya'
    TEKTAYA_BUKACONNECT = 'tektaya_bukaconnect'
    ACTIVE_PARTNER = 'active'
    THOR = 'thor'

    # partner sepulsa transaction status
    SEPULSA_PENDING = 'pending'
    SEPULSA_SUCCESS = 'success'
    SEPULSA_FAILED = 'failed'
    SEPULSA_CANCEL = 'cancel'

    DJI_PENDING = 'pending'
    DJI_SUCCESS = 'success'
    DJI_FAILED = 'failed'
    DJI_ERROR = 'error' # Bellerophone unhandled error

    ADINS_PENDING = 'pending'
    ADINS_SUCCESS = 'success'
    ADINS_FAILED = 'failed'

    BUKOPIN_PENDING = 'pending'
    BUKOPIN_SUCCESS = 'success'
    BUKOPIN_FAILED = 'failed'

    BNI_SUCCESS = 'success'
    BNI_FAILED = 'failed'
    BNI_TIMEOUT = 'timeout'

    PNL_SUCCESS = 'ACTC'
    PNL_FAILED = 'RJCT'
    PNL_PENDING = 'PDNG'

    AYOCONNECT_PENDING = 'pending'
    AYOCONNECT_SUCCESS = 'success'
    AYOCONNECT_FAILED = 'failed'

    TEKTAYA_PENDING = 'pending'
    TEKTAYA_SUCCESS = 'success'
    TEKTAYA_FAILED = 'failed'

    THOR_PENDING = 'pending'
    THOR_SUCCESS = 'success'
    THOR_FAILED = 'failed'

    # topup status (for translating partner status)
    PENDING = 0
    PROCESS = 1
    SUCCESS = 2
    FAILED = 3
    PAID = 4
    PARTNER_SUCCEEDED = 5
    PARTNER_FAILED = 6
    EXPIRED = 7
    CANCELLED = 8

    # transaction state
    TRANSACTION_PENDING = 'pending'
    TRANSACTION_PROCESSED = 'processed'
    TRANSACTION_SUCCEEDED = 'succeeded'
    TRANSACTION_FAILED = 'failed'

    # Pdam Operator active status mapping. Could be reused
    DELETED = -1
    INACTIVE = 0
    ACTIVE = 1

     # Pdam Operator have_issue mapping
     PDAM_NO_ISSUE = 0
     PDAM_HAVE_ISSUE = 1

    # partner transcation status
    PARTNER_STATUS = {
      SEPULSA => {
        SEPULSA_PENDING => PENDING,
        SEPULSA_SUCCESS => SUCCESS,
        SEPULSA_FAILED => FAILED,
        SEPULSA_CANCEL => FAILED
      },
      DJI => {
        DJI_PENDING => PENDING,
        DJI_SUCCESS => SUCCESS,
        DJI_FAILED => FAILED,
        DJI_ERROR => PENDING
      },
      ADINS => {
        ADINS_PENDING => PENDING,
        ADINS_SUCCESS => SUCCESS,
        ADINS_FAILED => FAILED
      },
      BUKOPIN => {
        BUKOPIN_PENDING => PENDING,
        BUKOPIN_SUCCESS => SUCCESS,
        BUKOPIN_FAILED => FAILED
      },
      BNI => {
        BNI_SUCCESS => SUCCESS,
        BNI_FAILED => FAILED,
      },
      PNL => {
        PNL_SUCCESS => SUCCESS,
        PNL_FAILED => PENDING, # Todo: Change to FAILED when automatic refund feature activated
        PNL_PENDING => PENDING
      },
      AYOCONNECT => {
        AYOCONNECT_PENDING => PENDING,
        AYOCONNECT_SUCCESS => SUCCESS,
        AYOCONNECT_FAILED => FAILED
      },
      TEKTAYA => {
        TEKTAYA_PENDING => PENDING,
        TEKTAYA_SUCCESS => SUCCESS,
        TEKTAYA_FAILED => FAILED
      },
      THOR => {
        THOR_PENDING => PENDING,
        THOR_SUCCESS => SUCCESS,
        THOR_FAILED => FAILED
      }
    }

    # format date
    YYYYMMDD = 'yyyymmdd'
    DDMMYYYY = 'ddmmyyyy'
    YYYYMM = 'yyyymm'
    MMMYYYY = 'mmmyyyy'
    DDMMMYYYY = 'ddmmmyyyy'
    MMMYY = 'mmmyy'

    # month with 3 chars (from ayoconnect)
    JANUARY   = 'JAN'
    FEBRUARY  = 'FEB'
    MARCH     = 'MAR'
    APRIL     = 'APR'
    MAY       = 'MAY'
    JUNE      = 'JUN'
    JULY      = 'JUL'
    AUGUST    = 'AUG'
    SEPTEMBER = 'SEP'
    OCTOBER   = 'OCT'
    NOVEMBER  = 'NOV'
    DECEMBER  = 'DEC'

    MONTH_MAP = {
      JANUARY   => 1,
      FEBRUARY  => 2,
      MARCH     => 3,
      APRIL     => 4,
      MAY       => 5,
      JUNE      => 6,
      JULY      => 7,
      AUGUST    => 8,
      SEPTEMBER => 9,
      OCTOBER   => 10,
      NOVEMBER  => 11,
      DECEMBER  => 12
    }

    # authorized roles
    AUTHORIZED_ROLES = [
      'admin',
      'antifraud',
      'bizdev',
      'business_partner',
      'cs_call_center',
      'cs_o2o',
      'cs_transaction',
      'customer_support',
      'disbursement',
      'finance',
      'promoted_cs_o2o',
      'reconcile',
      'sales',
      'cs_agent_tier_2',
      'cs_agent_tier_3',
      'ultraman'
    ]

    # authorized roles for exclusive controller
    EXCLUSIVE_AUTHORIZED_ROLES = Set.new([
      'admin',
      'bizdev',
      'business_partner',
      'cs_antifraud',
      'antifraud',
      'reconcile',
      'policy',
      'finance',
      'customer_support',
      'cs_transaction',
      'cs_non_transaction',
      'cs_o2o',
      'cs_call_center',
      'cs_agent_tier_2',
      'cs_agent_tier_3',
      'ultraman'
    ])

    #admin charge from sepulsa
    POSTPAID_ELECTRICITY_SEPULSA_CHARGE = ENV['POSTPAID_ELECTRICITY_SEPULSA_CHARGE'].to_i

    # admin charge from bukalapak
    POSTPAID_ELECTRICITY_BUKALAPAK_CHARGE = ENV['POSTPAID_ELECTRICITY_BUKALAPAK_CHARGE'].to_i
    PHONE_CREDIT_BUKALAPAK_CHARGE = 0

    # admin charge postpaid
    POSTPAID_ADMIN_CHARGE = POSTPAID_ELECTRICITY_SEPULSA_CHARGE + POSTPAID_ELECTRICITY_BUKALAPAK_CHARGE

    # bukalapak state
    BUKALAPAK_PROCESSED = 'processed'
    BUKALAPAK_REMIT = 'remitted'
    BUKALAPAK_REFUND = 'refunded'

    # TODO Refactor: Move this as a method in transaction's mixin instead
    TRX_STATE_TO_BL_STATE_MAP = {
      'paid' => BUKALAPAK_PROCESSED,
      'processed' => BUKALAPAK_PROCESSED,
      'succeeded' => BUKALAPAK_REMIT,
      'failed' => BUKALAPAK_REFUND,
      'partner_succeeded' => BUKALAPAK_REMIT,
      'partner_failed' => BUKALAPAK_REFUND,
      'cancelled' => BUKALAPAK_REFUND
    }
    BL_STATE_TO_TEMPLATE_MAP = {
      BUKALAPAK_REMIT => 'success',
      BUKALAPAK_REFUND => 'error'
    }

    # RabbitMQ exchange name
    # .new because queue type was changed
    EXCHANGE_CREATE = 'postpaid.create.new'
    EXCHANGE_CONFIRM = 'postpaid.confirm.new'
    EXCHANGE_UPDATE = 'postpaid.update2.new'
    EXCHANGE_MAILER = 'postpaid.mailer.new'
    EXCHANGE_PDAM_CONFIRM = 'pdam.confirm.new'
    EXCHANGE_ELECTRICITY_CONFIRM = 'electricity.confirm.new'
    EXCHANGE_BPJS_KESEHATAN_CONFIRM = 'bpjs_kesehatan.confirm.new'
    EXCHANGE_CREDIT_CARD_BILL_CREATE = 'credit_card_bill.create_2'
    EXCHANGE_SEPULSA_UPDATE_STATUS = 'olympus.sepulsa_update_status'
    EXCHANGE_RECURRENCE_NOTIFIER = 'recurrence.notify.new'
    EXCHANGE_VEHICLE_TAX_CONFIRM = 'vehicle_tax.confirm.new'
    EXCHANGE_VEHICLE_TAX_PAYMENT = 'vehicle_tax.payment.new'
    EXCHANGE_VEHICLE_TAX_UPDATE = 'vehicle_tax.update.new'
    EXCHANGE_VEHICLE_TAX_MAILER = 'vehicle_tax.mailer.new'
    #RabbitMQ default constant
    DEFAULT_CONFIRM_JOB_DELAY = ENV['DEFAULT_CONFIRM_JOB_DELAY'].to_i # 15 minutes

    # TODO Refactor: Move this method as transaction's method instead
    # prefix
    ELECTRICITY_POSTPAID_PREFIX = 'ELP'
    BPJS_KESEHATAN_PREFIX = 'BKS'
    PDAM_PREFIX = 'PDM'
    PHONE_CREDIT_POSTPAID_PREFIX = 'PCP'
    CREDIT_CARD_BILL_PREFIX = "CC"
    BPJS_KETENAGAKERJAAN_PREFIX = 'BTK'

    # Toggles
    EMAIL_TELOLET_TOGGLE = 'email_telolet_toggle'
    ELECTRICITY_EMAIL_TELOLET_TOGGLE = 'electricity_email_telolet_toggle'

    module BalanceTracker
      module ElectricityPostpaid
        MITRA_BALANCE = 'electricity_postpaid_balance_mitra'
        BUKALAPAK_BALANCE = 'electricity_postpaid_balance'

        MITRA_THRESHOLD = 'electricity_postpaid_threshold_mitra'
        BUKALAPAK_THRESHOLD = 'electricity_postpaid_threshold'
      end
    end

    # name for differentiate product
    ELECTRICITY_PRODUCT = 'electricity_postpaid'
    BPJS_KESEHATAN_PRODUCT = 'bpjs-kesehatan'
    PDAM_PRODUCT = 'pdam'
    PHONE_CREDIT_PRODUCT = 'phone-credit-postpaid'
    CREDIT_CARD_BILL_PRODUCT = 'credit-card-bill'
    VEHICLE_TAX_PRODUCT = 'vehicle_tax'
    BPJS_KETENAGAKERJAAN_PRODUCT = 'bpjs-ketenagakerjaan'

    BALANCE_NOTIFER_TEMPLATE = /^olympus_recurrence_topup_deposit/
    STOP_NOTIFIER_TEMPLATE = /^olympus_recurrence_unsubscribe_success/
    SUBSCRIBE_SUCCESS_NOTIFIER_TEMPLATE = /^olympus_recurrence_subscribe_success/
    SUCCESS_TRANSACTION_NOTIFIER_TEMPLATE = /^olympus_recurrence_transaction_success/
    ERROR_TRANSACTION_NOTIFIER_TEMPLATE = /^olympus_recurrence_transaction_error/

    # TODO Refactor: Move this as transaction's method instead
    # keys: trx class and state
    EMAIL_TEMPLATE = {
      ::PostpaidTransaction => {
        'succeeded' => 'postpaid_electricity_succeed',
        'failed' => 'postpaid_electricity_failed',
        'partner_succeeded' => 'postpaid_electricity_succeed',
        'partner_failed' => 'postpaid_electricity_failed',
      },
      ::BpjsKesehatanTransaction => {
        'succeeded' => 'bpjs_kesehatan_succeed',
        'failed' => 'bpjs_kesehatan_failed',
        'partner_succeeded' => 'bpjs_kesehatan_succeed',
        'partner_failed' => 'bpjs_kesehatan_failed',
      },
      ::PdamTransaction => {
        'succeeded' => 'pdam_succeed',
        'failed' => 'pdam_failed',
        'partner_succeeded' => 'pdam_succeed',
        'partner_failed' => 'pdam_failed',
      },
      ::PhoneCreditPostpaidTransaction => {
        'succeeded' => 'phone_credit_postpaid_succeed',
        'failed' => 'phone_credit_postpaid_failed',
        'partner_succeeded' => 'phone_credit_postpaid_succeed',
        'partner_failed' => 'phone_credit_postpaid_failed',
      },
      ::CreditCardBillTransaction => {
        'succeeded' => 'credit_card_bill_succeed',
        'failed' => 'credit_card_bill_failed',
        'partner_succeeded' => 'credit_card_bill_succeed',
        'partner_failed' => 'credit_card_bill_failed',
      },
    }

    PARTNER_OFFICIAL_NAME = {
      'sepulsa' => 'PT Sepulsa Teknologi Indonesia',
      'dji' => 'PT Design Jaya Indonesia',
      'dji-pdam-to' => 'PT Design Jaya Indonesia',
      'dji-bpjs' => 'Bank Mandiri - JPA - DJI',
      'adins' => 'PT Adicipta Dinamika Inovasi',
      'bni' => 'PT BNI Tbk',
      'bukopin' => 'PT Bank Bukopin Tbk',
      'pnl' => 'PT Bank DBS Indonesia',
      'visa' => 'PT Bank CIMB Niaga', # TBC
      'ayoconnect' => 'PT. Ayopop Teknologi Indonesia',
      'tektaya' => 'PT Teknologi Cipta Raya',
      'sepulsa_bukaconnect' => 'PT Sepulsa Teknologi Indonesia',
      'bukopin_bukaconnect' => 'PT Bank Bukopin Tbk',
      'ayoconnect_bukaconnect' => 'PT. Ayopop Teknologi Indonesia',
      'tektaya_bukaconnect' => 'PT Teknologi Cipta Raya',
      'vsi_thor' => 'PT Value Stream Indonesia',
      'mkm_thor' => 'PT Magna Karsa Mulya',
      'fortuna_thor' => 'PT. Fortuna Mediatama',
      'cimbniaga_thor' => 'PT Bank CIMB Niaga',
      'sat_thor' => 'PT Satria Abadi Terpadu',
      'bms_thor' => 'PT Bimasakti Multi Sinergi'
    }

    NORMAL_USER_TRANSACTION_TYPE = 0
    AGENT_USER_TRANSACTION_TYPE = 1
    BUKA_PENGADAAN_USER_TRANSACTION_TYPE = 2
    COLLECTING_AGENT_USER_TRANSACTION_TYPE = 4

    MITRA_PLATFORM = 'mitra'
    MARKETPLACE_PLATFORM = 'marketplace'

    NORMAL_BUYER_TYPE = 'normal'
    AGENT_BUYER_TYPE = 'agent'
    BUKA_PENGADAAN_BUYER_TYPE = 'procurement'

    RECURRENCE_ELIGIBLE_BUYER_TYPE = AGENT_BUYER_TYPE
    COLLECTING_AGENT_BUYER_TYPE = 'collecting_agent'

    # DJI ISO constants
    DJI_CHECK_MTI   = '0200'
    DJI_INQUIRY_MTI = '0200'
    DJI_NETWORK_MTI = '0800'
    DJI_PAYMENT_MTI = '0200'

    DJI_CARD_ACCEPTOR_NAME = 'PT.Bukalapak'

    # ISO bit48 DJI format
    DJI_BPJS_KESEHATAN_INQUIRY_ATTR = {
      product_code: 6,
      reserved: 1,
      customer_number: 20,
      bills_length: 2,
      date_server: 8,
      time_server: 6,
      customer_name: 30,
      amount: 12,
      admin_fee: 12,
      reference: 64,
      switch_id: 10
    }

    # RIP Format from partner, because member detail cut the inquiry format
    DJI_BPJS_KESEHATAN_INQUIRY_DETAIL_ATTR_PRE = {
      customer_number: 20,
      branch_name: 30,
      payment_period: 2,
      family_member_count: 1
    }

    DJI_BPJS_KESEHATAN_MEMBER_DETAIL_ATTR_MEMBER = {
      member_number: 20,
      name: 30,
      premium: 12,
      balance: 12
    }

    DJI_BPJS_KESEHATAN_INQUIRY_DETAIL_ATTR_POST = {
      bank_admin: 12,
      total: 12
    }

    DJI_BPJS_KESEHATAN_PAYMENT_DETAIL_ATTR = {
      customer_number: 20,
      customer_name: 30,
      reference: 32,
      member_count: 1,
      payment_period: 2,
      bill_amount: 12,
      bank_admin: 12,
      total: 12,
      info: 100
    }

    module MwsJobs
      CREDIT_CARD_BILL_CREATE = 'credit-card-bill-create'
      POSTPAID_CREATE = 'postpaid-create'
      POSTPAID_CONFIRM = 'postpaid-confirm'
      POSTPAID_SEND_EMAIL = 'postpaid-send-email'
      POSTPAID_UPDATE_REMOTE = 'postpaid-update-remote'
      POSTPAID_CALLBACK_SEPULSA = 'postpaid-callback-sepulsa'
      POSTPAID_SIEVEX_PREDICT = 'postpaid-sievex-predict'
    end

    BALANCE_TYPE = {
      normal: 'bukalapak',
      agent: 'mitra',
      collecting_agent: 'bukaconnect',
    }

    PARTNER_BASIC_AUTH_MAP = {
      AYOCONNECT => {
        username: ENV['OLYMPUS_USERNAME_FOR_AYOCONNECT'],
        password: ENV['OLYMPUS_PASSWORD_FOR_AYOCONNECT'],
      },
      THOR => {
        username: ENV['THOR_CALLBACK_USERNAME'],
        password: ENV['THOR_CALLBACK_PASSWORD'],
      }
    }

    module Autoswitch
      AUTOSWITCH_ELECTRICITY_KEY = 'electricity_autoswitch:partner'
      AUTOSWITCH_PDAM_KEY = 'pdam_autoswitch:group_member'
      SWITCHBACK_ELECTRICITY_KEY = 'electricity_autoswitch:switchback'
      SWITCHBACK_PDAM_KEY = 'pdam_autoswitch:switchback'

      PARTNER_SWITCHBACK_DURATION = Config::AutoswitchSwitchbackDuration.get_duration_by_day(60)
    end
  end
end
