# frozen_string_literal: true
require 'rufus-scheduler'

module Subscribers
  class Base
    include PostpaidTransactionUtility
    include LoggerUtility

    SUBSCRIBER_MAX_RETRY = ENV['SUBSCRIBER_MAX_RETRY'].to_i

    def self.run(*args, &block)
      new(*args, &block).run
    end

    def run
      scheduler = Rufus::Scheduler.new
      subscriber = subscription.listen do |message|
        params = JSON.parse(message.data).with_indifferent_access

        Observer.measure(Observer::Metric::WORKER,  action: topic_name, product: params[:product_type]) do
          # Retry flag
          @should_retry = true

          # Breakdown the params
          delay = params.delete(:delay) || Subscribers::Topics.get_delay(topic_name)
          fixed_delay = params.delete(:fixed_delay) || false
          retry_count = params[:retry_count].to_i
          remote_id = params[:remote_id]
          product_type = params[:product_type]
          options = params[:options] || {}
          tags = %W[subscriber #{topic_name.split('.').last} #{product_type} retry_#{retry_count}]

          # job is consumed
          LogBook.info("#{topic_name.split('.').last} for #{product_type} is consumed", tags, track_id: remote_id)

          scheduler.in delay do
            ActiveRecord::Base.connection_pool.with_connection do
              transaction = get_transaction(product_type, remote_id)
              raise Exceptions::TransactionNotFound.new if transaction.nil?

              tags << partner_name(transaction)
              process_task(transaction, options, tags)
            end
          rescue StandardError => e
            # Log the shit
            error_message = "[#{e.class}] #{e.message}"
            LogBook.error(error_message, tags, e.backtrace.take(5), track_id: remote_id)

            # Re-publish the message if allowed
            publish_message(params, retry_count, delay, fixed_delay) if @should_retry && retry_count < SUBSCRIBER_MAX_RETRY
          ensure
            message.acknowledge!
          end

          # job is successfully processed
          LogBook.info("#{topic_name.split('.').last} for #{product_type} has been scheduled to run after #{delay.round(2)} second", tags, track_id: remote_id)
        end
      end

      subscriber.start
      LogBook.info("Subscriber `#{topic_name}` is up.", %w[subscriber start])
      if Rails.env.test?
        sleep 2
      else
        sleep
      end
    ensure
      LogBook.warn("Stopping subscriber `#{topic_name}`", %w[subscriber stop])
      subscriber.stop!
    end

    private

    def partner_name(transaction)
      return unless transaction.present?
      case transaction
      when ::CreditCardBillTransaction
        transaction.partner.name
      when ::PostpaidTransaction, ::PhoneCreditPostpaidTransaction, ::BpjsKesehatanTransaction, ::PdamTransaction
        transaction.partner
      end
    rescue
      nil
    end

    def topic_name
      raise NotImplementedError, 'You must implement `topic_name`.'
    end

    def process_task(transaction)
      raise NotImplementedError, 'You must implement `process_task`.'
    end

    def get_transaction(product_type, remote_id)
      transaction_klass = PRODUCT_TO_TRX_KLASS_MAP[product_type]
      transaction_klass.find_by_remote_transaction_id(remote_id)
    end

    def publish_message(params, retry_count, delay, fixed_delay = false)
      new_delay = fixed_delay ? delay : (delay + (delay/(retry_count+1)) + rand(delay))
      params[:delay] = new_delay
      params[:retry_count] = retry_count+1
      params[:fixed_delay] = fixed_delay
      GcpsPublisher.publish(topic_name, params, track_id: params[:remote_id])
    end

    def subscription
      subscription = GoogleCloudPubSub.subscription(topic_name)
      if subscription.nil?
        topic = GoogleCloudPubSub.topic(topic_name)
        if topic.nil?
          raise Exceptions::PubsubTopicNotFound.new if Rails.env.production?
          topic = GoogleCloudPubSub.create_topic(topic_name)
        end
        subscription = topic.subscribe(topic_name)
      end
      subscription
    end
  end
end
