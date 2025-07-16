module CreditCardBill
  module TransactionStateMachine
    extend ActiveSupport::Concern

    included do
      # using gem AASM for state
      # because its compatible with rails 5
      include AASM

      aasm column: :state, enum: true, create_scopes: false do
        state :pending, initial: true
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

        event :fail do
          transitions from: :partner_failed, to: :failed
        end

        event :cancel do
          transitions from: [:pending, :paid], to: :cancelled
        end

        event :expire do
          transitions from: :pending, to: :expired
        end
      end

      def transition_callback(transaction)
        transaction.send("#{aasm.to_state}_at=", Time.now.utc)
        # Sievex schema need to be updated if new state added
        next_state = aasm.to_state || :pending
        Sievex::Send.new(transaction, next_state).run! if Toggles::OlympusSievexSend.active?
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
end
