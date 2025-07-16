module Action
  module CreditCardBiller
    class Create

      DEFAULT_IMAGE_URL = "https://s2.bukalapak.com/images/desktop/aset-brand/section1-3.png"
      DEFAULT_TERMS_AND_CONDITIONS = "<ol><li>Pastikan kamu sudah mengetahui jumlah tagihan dan min. pembayaran untuk tagihan kartu kreditmu.</li><li>Biaya admin akan ditambahkan pada tagihan di bulan berikutnya.</li></ol>"

      def initialize(params)
        @params = params
      end

      def run!
      biller =  ::CreditCardBiller.new(
                      name: @params[:name],
                      active: @params[:active],
                      image_url: @params[:image_url] || DEFAULT_IMAGE_URL,
                    )
        biller.save!
        biller
      end
    end
  end
end
