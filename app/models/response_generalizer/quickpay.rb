module ResponseGeneralizer
  class Quickpay
    ATTRIBUTES = %w(customer_number customer_name paid_until operator biller provider_name provider_product_name provider_logo_url)
    DESCRIPTIONS = {
      customer_name: 'Nama Lengkap',
      customer_number: {
        'bpjs-kesehatan' => 'No. Kepesertaan/No. VA Keluarga',
        'electricity_postpaid' => 'Nomor Meter/ID Pelanggan',
        'pdam' => 'Nomor Pelanggan',
        'phone-credit-postpaid' => 'Nomor Telepon',
        'multifinance' => 'Nomor Kontrak'
      },
      family_member_count: 'Jumlah Keluarga'
    }.freeze

    def initialize(object, remote_type)
      @object = object
      @remote_type = remote_type
    end

    def remote_type
      @remote_type
    end

    def descriptions
      DESCRIPTIONS
    end

    def amount
      @object.amount rescue @object[:amount] || @object[:total_amount]
    end

    ATTRIBUTES.each do |method|
      define_method(method) do
        @object.public_send(method) rescue @object[method.to_sym] rescue nil
      end
    end

    DESCRIPTIONS.except(*ATTRIBUTES).each do |key, _value|
      define_method(key) do
        @object.public_send(key) rescue @object[key.to_sym] rescue nil
      end
    end

    def provider
      provider_hash = {
        name: provider_name,
        product_name: provider_product_name,
        logo_url: provider_logo_url
      }.compact

      provider_hash.any? ? provider_hash : nil
    end

    def image_url
      case @remote_type
      when 'bpjs-kesehatan'
        'https://s4.bukalapak.com/images/virtual_product/logo_bpjs.png'
      when 'electricity_postpaid'
        'https://s4.bukalapak.com/images/virtual_product/logo_pln.png'
      else
        nil
      end
    end

    def due_day
      case @remote_type
      when 'pdam'
        operator.due_day rescue operator[:due_day] rescue nil
      when 'bpjs-kesehatan'
        10
      when 'electricity_postpaid'
        20
      else
        nil
      end
    end
  end
end
