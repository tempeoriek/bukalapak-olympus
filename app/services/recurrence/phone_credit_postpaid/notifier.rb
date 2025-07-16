module Recurrence
  module PhoneCreditPostpaid
    class Notifier

      def self.subscribe_success(template)
        payload_onsite = {
          user_id: template.buyer_id,
          body: {
            title:  'Kamu Berhasil Daftar Transaksi Rutin',
            body:   'Yeay! Transaksi Pulsa Pascabayar akan didebit otomatis tiap bulan. Lihat info selengkapnya.',
            image: nil,
            url: "#{ENV["BUKALAPAK_WEB_URL"]}/transaksi-rutin",
            tag: 'phone-credit-postpaid-recurrence-subscribe-success'
          }
        }
        payload_push = {
          data: {
            user_id: template.buyer_id,
            headings: 'Kamu Berhasil Daftar Transaksi Rutin',
            contents: 'Yeay! Transaksi Pulsa Pascabayar akan didebit otomatis tiap bulan. Lihat info selengkapnya.',
            tag: 'phone-credit-postpaid-recurrence-subscribe-success',
            url: "#{ENV["BUKALAPAK_WEB_URL"]}/transaksi-rutin"
          }
        }

        send_notif(payload_onsite, payload_push)
      end

      def self.insufficient_balance(template)
        payload_onsite = {
          user_id: template.buyer_id,
          body: {
            title:  'Saldo Tidak Cukup untuk Transaksi Rutin',
            body:   'Jumlah Saldo/DANA/limit kartu kamu tidak cukup untuk Transaksi Rutin Pulsa Pascabayar.',
            image: nil,
            url: "#{ENV["BUKALAPAK_WEB_URL"]}/transaksi-rutin",
            tag: 'phone-credit-postpaid-recurrence-insufficient-balance'
          }
        }
        payload_push = {
          data: {
            user_id: template.buyer_id,
            headings: 'Saldo Tidak Cukup untuk Transaksi Rutin',
            contents: 'Jumlah Saldo/DANA/limit kartu kamu tidak cukup untuk Transaksi Rutin Pulsa Pascabayar.',
            tag: 'phone-credit-postpaid-recurrence-insufficient-balance',
            url: "#{ENV["BUKALAPAK_WEB_URL"]}/transaksi-rutin"
          }
        }

        send_notif(payload_onsite, payload_push)
      end

      def self.stop_subscribing(template)
        payload_onsite = {
          user_id: template.buyer_id,
          body: {
            title:  'Kamu Sudah Menghentikan Transaksi Rutin',
            body:   'Transaksi Rutin Pulsa Pascabayar sudah dihentikan. Kamu bisa aktifkan ulang di halaman Akun.',
            image: nil,
            url: "#{ENV["BUKALAPAK_WEB_URL"]}/transaksi-rutin",
            tag: 'phone-credit-postpaid-recurrence-stop-subscribing'
          }
        }
        payload_push = {
          data: {
            user_id: template.buyer_id,
            headings: 'Kamu Sudah Menghentikan Transaksi Rutin',
            contents: 'Transaksi Rutin Pulsa Pascabayar sudah dihentikan. Kamu bisa aktifkan ulang di halaman Akun.',
            tag: 'phone-credit-postpaid-recurrence-stop-subscribing',
            url: "#{ENV["BUKALAPAK_WEB_URL"]}/transaksi-rutin"
          }
        }

        send_notif(payload_onsite, payload_push)
      end

      def self.reminder(template)
        payload_onsite = {
          user_id: template.buyer_id,
          body: {
            title:  'Jadwal Transaksi Rutin Sebentar Lagi',
            body:   '2 hari lagi waktunya transaksi Pulsa Pascabayar. Pastikan Saldo/DANA/limit kartu kamu cukup, ya.',
            url: "#{ENV["BUKALAPAK_WEB_URL"]}/transaksi-rutin",
            tag: 'phone-credit-postpaid-recurrence-reminder',
            image: nil
          }
        }
        payload_push = {
          data: {
            user_id: template.buyer_id,
            headings: 'Jadwal Transaksi Rutin Sebentar Lagi',
            contents: '2 hari lagi waktunya transaksi Pulsa Pascabayar. Pastikan Saldo/DANA/limit kartu kamu cukup, ya.',
            url: "#{ENV["BUKALAPAK_WEB_URL"]}/transaksi-rutin",
            tag: 'phone-credit-postpaid-recurrence-reminder'
          }
        }
        send_notif(payload_onsite, payload_push)
      end

      private

      def self.send_notif(p_onsite, p_push)
        Escrow::SendOnsiteNotif.new(p_onsite).run! if Toggles::OnSiteNotif.active?
        Escrow::SendPushNotif.new(p_push).run! if Toggles::PushNotif.active?
      end
    end
  end
end
