module Internal
  class PhoneCreditController < Internal::PostpaidController

    PRODUCT_NAME = PHONE_CREDIT_PRODUCT

    def status
      super {
        |id|
          PhoneCreditPostpaidTransaction.find_by_id(id)
      }
    end
  end
end
