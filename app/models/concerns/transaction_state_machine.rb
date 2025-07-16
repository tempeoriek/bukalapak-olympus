module TransactionStateMachine
  extend ActiveSupport::Concern

  included do
    # using gem AASM for state
    # because its compatible with rails 5
    include AASM

    aasm column: :state, enum: true, create_scopes: false do
      state :pending, initial: true, after_enter: :transition_callback
      state :paid
      state :cancelled
      state :expired
      state :processed
      state :partner_succeeded
      state :partner_failed
      state :succeeded
      state :failed

      after_all_transitions :transition_callback

      event :pay do
        transitions from: :pending, to: :paid
      end

      event :process do
        transitions from: :paid, to: :processed
      end

      event :partner_success do
        transitions from: :processed, to: :partner_succeeded
      end

      event :partner_fail do
        transitions from: :processed, to: :partner_failed
      end

      event :success do
        transitions from: :partner_succeeded, to: :succeeded, after: :publish_postpaid_paid_to_remit_metrics
      end

      event :force_success do
        transitions from: [:paid, :processed, :partner_succeeded], to: :succeeded
      end

      event :fail do
        transitions from: :partner_failed, to: :failed
      end

      event :force_fail do
        transitions from: [:paid, :processed, :partner_failed], to: :failed
      end

      event :cancel do
        transitions from: [:pending, :paid], to: :cancelled
      end

      event :expire do
        transitions from: :pending, to: :expired
      end
    end

    def transition_callback
      self.send("#{aasm.to_state}_at=", Time.now.utc) if aasm.to_state

      next_state = aasm.to_state || :pending
      # Metric
      tags = {
        product: product_type,
        state: next_state,
        partner: partner_name,
        transaction_type: transaction_type,
        biller_product: biller_product
      }
      Observer.counter(Observer::Metric::STATE, 1, tags)

      if %i(paid succeeded failed cancelled).include?(next_state.to_sym)
        Observer.distribution(Observer::Metric::GMV, amount, tags)
      end
      # Sievex schema need to be updated if new state added
      Sievex::Send.new(self, next_state).run! if Toggles::OlympusSievexSend.active? && self.is_a?(CreditCardBillTransaction)
    end

    def publish_postpaid_paid_to_remit_metrics
      tags = {
        product: product_type,
        state: self.state,
        partner: partner_name,
        transaction_type: transaction_type,
        biller_product: biller_product
      }

      duration = Time.now - self.paid_at
      Observer.histogram(Observer::Metric::TIME_TO_SUCCEED, duration, tags)
    end
  end
end
