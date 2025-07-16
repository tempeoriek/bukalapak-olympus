#!/usr/bin/env rake
require 'sneakers/tasks'
require File.expand_path('../config/application', __FILE__)
Rails.application.load_tasks

require 'erb'
require 'open3'
require 'yaml'
require './config/environment'
# require 'rspec/core/rake_task'

Registry = "registry.bukalapak.io"
OutputDir = "./deploy/_outputs"
DeployDir = "./deploy"
ServiceName = "olympus_old_deployment"

def current_git_version
  `git show -q --format=%H`.strip[0..7]
end

def environments
  YAML.load(File.read "./deploy/deploy.yml")
end

namespace :olympus do
  version = current_git_version
  raise "you need to specify $VERSION or $TAG" unless version
  no_cache = "--no-cache"

  task all: [:build, :push, :deployment]

  task :build do
    puts cmd = "docker build -t #{Registry}/bukalapak/olympus:olympus-#{version} -f ./deploy/olympus/Dockerfile ."
    puts `#{cmd}`
    puts cmd = "docker build -t #{Registry}/bukalapak/olympus:olympus-background-#{version} -f ./deploy/olympus-background/Dockerfile ."
    puts `#{cmd}`
  end

  task :push do
    puts cmd = "docker push #{Registry}/bukalapak/olympus:olympus-#{version}"
    puts `#{cmd}`
    puts cmd = "docker push #{Registry}/bukalapak/olympus:olympus-background-#{version}"
    puts `#{cmd}`
  end

  task :deployment do
    deployment_file = "olympus_deployment.yml"
    service_file = "service.yml"
    job_file = "olympus_background_deployment.yml"
    template_deployment = "./deploy/#{ServiceName}/#{deployment_file}.erb"
    template_service = "./deploy/#{ServiceName}/#{service_file}.erb"
    template_job = "./deploy/#{ServiceName}/#{job_file}.erb"
    environments.each do |environment, services|
      b = binding
      services.each do |_service, options|
        options.each do |key, value|
          b.local_variable_set(key, value)
        end
      end
      FileUtils.mkdir_p "#{OutputDir}/#{environment}/"
      File.write("#{OutputDir}/#{environment}/olympus_deployment.yml", ERB.new(File.read(template_deployment)).result(b))
      File.write("#{OutputDir}/#{environment}/service.yml", ERB.new(File.read(template_service)).result(b))
      File.write("#{OutputDir}/#{environment}/olympus_background_deployment.yml", ERB.new(File.read(template_job)).result(b))
      puts "#{environment} deployment file generated at  #{OutputDir}/#{environment}/deployment.yml"
      puts "#{environment} service file generated at #{OutputDir}/#{environment}/service.yml"
    end
  end
end

namespace :transaction do
  namespace :cleanup do
    task :all do
      include PostpaidTransactionUtility

      state_function = {
        'paid': Proc.new { |trx| Action::PostpaidTransaction::Process.new(trx).run! },
        'processed': Proc.new { |trx| Action::PostpaidTransaction::ManualConfirm.new(trx).run! },
        'partner_succeeded': Proc.new { |trx| Action::PostpaidTransaction::UpdateRemote.new(trx).run! },
        'partner_failed': Proc.new { |trx| Action::PostpaidTransaction::UpdateRemote.new(trx).run! }
      }

      transaction_klasses = [
        PhoneCreditPostpaidTransaction,
        BpjsKesehatanTransaction,
        PdamTransaction,
        PostpaidTransaction,
        BpjsKetenagakerjaanTransaction
      ]

      transaction_klasses.each do |transaction_klass|
        product_type = TRX_KLASS_TO_PRODUCT_MAP[transaction_klass]
        opts = { product_type: product_type }

        state_function.keys.each do |state|
          state_at = "#{state}_at".to_sym
          transactions = transaction_klass.where(state: state, state_at => 5.day.ago..15.minute.ago)

          opts[:state] = state
          Observer.counter(Observer::Metric::STUCK, transactions.count, opts)

          proc_func = state_function[state]

          transactions.each do |trx|
            begin
              proc_func.call(trx)
            rescue => e
              Logger2.error({
                tags: %W[#{product_type} #{state} cleanup error],
                backtrace: e&.backtrace.take(7).join("\n"),
                message: e.message,
                track_id: trx.id
              })
            end
          end
        end
      end
    end

    task :credit_card_bill do
      include LoggerUtility

      begin
        start_worker_log("Start Credit Card Bill Transaction Cleanup", ['credit_card_bill', 'cleanup'], { severity: 'INFO', datetime: Time.now.to_s })

        current_date = ::Time.current.in_time_zone('Jakarta').strftime("%Y-%m-%d")
        Action::CreditCardBillTransaction::Reconcile.new(current_date, current_date).run!

        stop_worker_log("Finish Credit Card Bill Transaction Cleanup", ['credit_card_bill', 'cleanup', 'success'], { severity: 'INFO', datetime: Time.now.to_s })
      rescue => e
        failed_worker_log("Failed Credit Card Bill Transaction Cleanup - #{e.message}", ['credit_card_bill', 'cleanup', 'error'], { severity: 'ERROR', datetime: Time.now.to_s })
      end
    end

    task :ccb_visa_token do
      include LoggerUtility

      # Based on the data from 2020-03-01 - 2020-05-31,
      # 95th percentile of created to paid time is around 2 hours
      # Reference: https://docs.google.com/spreadsheets/d/11GF93GbD7F3lJQycNEZlqe1QKohOlotkHpg5YzVuJVk/edit?ts=5ed8abeb#gid=2063294494
      now        = Time.current.utc.in_time_zone('Jakarta')
      start_time = now.beginning_of_day
      end_time   = now - 2.hours
      visa_trx   = CreditCardBillTransaction
                    .joins(:credit_card_bill_partner)
                    .where({
                      created_at: start_time..end_time,
                      :credit_card_bill_partners => { name: 'visa' }
                    })
                    .where.not({ token: nil })
      visa_trx.find_each do |trx|
        begin
          start_worker_log("Start Visa Credit Card Bill Clear Token", ['credit_card_bill', 'visa', 'delete_token'], { track_id: trx.id })
          Action::CreditCardBillTransaction::DeleteToken.new(trx).run!
          stop_worker_log("Finish Visa Credit Card Bill Clear Token", ['credit_card_bill', 'visa', 'delete_token', 'success'], { track_id: trx.id })
        rescue => e
          failed_worker_log("Failed Visa Credit Card Bill Clear Token - #{e.message}", ['credit_card_bill', 'visa', 'delete_token', 'error'], { track_id: trx.id })
        end
      end
    end
  end
end

namespace :olympus do
  namespace :tektaya do
    task :login do
      include LoggerUtility
      include Channel::Tektaya::Helpers::Constants

      # Try to re-hit when failed
      MAX_RETRY          = 3.freeze

      # We put a sleep time when retrying the request to minimize failure (like timeouts)
      DEFAULT_SLEEP_TIME = 5.freeze

      retry_count = 0
      begin
        channel_class = Channel::Tektaya::Helpers::Login
        channel_class.new(MITRA_BUYER_TYPE).request
        channel_class.new(NORMAL_BUYER_TYPE).request
        channel_class.new(BUKACONNECT_BUYER_TYPE).request

        stop_worker_log("Succeed login Tektaya - retry #{retry_count}", ['rake', 'login', 'tektaya'], { severity: 'INFO', datetime: Time.now.to_s })
      rescue => e
        retry_count += 1
        failed_worker_log("Failed to login Tektaya - #{e.message} - retry #{retry_count}", ['rake', 'login', 'tektaya', 'error'], { severity: 'ERROR', datetime: Time.now.to_s })
        sleep(DEFAULT_SLEEP_TIME)
        retry if retry_count < MAX_RETRY
      end
    end
  end

  namespace :bni do
    task :upload do
      include LoggerUtility

      retry_count = 0
      begin
        biller_types = %w[BNI NON_BNI]

        today = Time.current.utc.in_time_zone('Jakarta')

        start_time = today.yesterday.beginning_of_day
        end_time = today.beginning_of_day

        biller_types.each do |biller_type|
          filename = "BUKALAPAK#{start_time.strftime('%Y%m%d')}.csv"
          filename = 'BNI_' + filename if biller_type == 'BNI'

          response = Action::CreditCardBillTransaction::UploadSftp.new(start_time, end_time, filename, biller_type).run!

          stop_worker_log("Succeed push BNI's trx to SFTP - #{response} - retry #{retry_count}", ['rake', 'sftp', 'bni'], { severity: 'INFO', datetime: Time.now.to_s })
        end

      rescue => e
        retry_count += 1
        failed_worker_log("Failed push BNI's trx to SFTP - #{e.message} - retry #{retry_count}", ['rake', 'sftp', 'bni', 'error'], { severity: 'ERROR', datetime: Time.now.to_s })
        sleep(10)
        retry if retry_count < 3
      end
    end

    task :send_reconcile_email do
      include LoggerUtility

      retry_count = 0
      begin
        today = Time.current.utc.in_time_zone('Jakarta')

        start_time = today.yesterday.beginning_of_day
        end_time = today.beginning_of_day

        filename = "BUKALAPAK#{start_time.strftime('%Y%m%d')}.csv"

        response = Action::CreditCardBillTransaction::SendEmailReconcile.new(start_time, end_time, filename).run!

        stop_worker_log("Successfully sent email reconcile BNI's trx - #{response} - retry #{retry_count}", ['rake', 'email_reconcile', 'bni'], { severity: 'INFO', datetime: Time.now.to_s })
      rescue => e
        retry_count += 1
        failed_worker_log("Failed to send email reconcile BNI's trx - #{e.message} - retry #{retry_count}", ['rake', 'email_reconcile', 'bni', 'error'], { severity: 'ERROR', datetime: Time.now.to_s })
        sleep(10)
        retry if retry_count < 3
      end


    end
  end

  namespace :visa do
    task :cleanup_token do
      include LoggerUtility

      # Based on the data from 2020-03-01 - 2020-05-31,
      # 95th percentile of created to paid time is around 2 hours
      # Reference: https://docs.google.com/spreadsheets/d/11GF93GbD7F3lJQycNEZlqe1QKohOlotkHpg5YzVuJVk/edit?ts=5ed8abeb#gid=2063294494
      now        = Time.current.utc.in_time_zone('Jakarta')
      start_time = now.beginning_of_day
      end_time   = now - 2.hours
      visa_trx   = CreditCardBillTransaction
                    .joins(:credit_card_bill_partner)
                    .where({
                      created_at: start_time..end_time,
                      :credit_card_bill_partners => { name: 'visa' }
                    })
                    .where.not({ token: nil })
      visa_trx.find_each do |trx|
        begin
          start_worker_log("Start Visa Credit Card Bill Clear Token", ['credit_card_bill', 'visa', 'delete_token'], { track_id: trx.id })
          Action::CreditCardBillTransaction::DeleteToken.new(trx).run!
          stop_worker_log("Finish Visa Credit Card Bill Clear Token", ['credit_card_bill', 'visa', 'delete_token', 'success'], { track_id: trx.id })
        rescue => e
          failed_worker_log("Failed Visa Credit Card Bill Clear Token - #{e.message}", ['credit_card_bill', 'visa', 'delete_token', 'error'], { track_id: trx.id })
        end
      end
    end
  end

  namespace :autoswitch do
    task :switchback do
      include LoggerUtility
      
      tags = ['autoswitch', 'switchback']
      title = "Autoswitch Switchback Mechanism"

      begin
        start_worker_log("Start #{title}", tags, { severity: 'INFO', datetime: Time.now.to_s })

        electricity_switchback = Action::ElectricityAutoswitch::Mechanism::Switchback.new.perform
        pdam_switchback = Action::PdamAutoswitch::Mechanism::Switchback.new.perform

        stop_worker_log(
          "Finish #{title}",
          tags + ['success'],
          { 
            severity: 'INFO',
            datetime: Time.now.to_s,
            electricity: electricity_switchback,
            pdam: pdam_switchback
          }
        )
      rescue => e
        failed_worker_log("Failed #{title} - #{e.message}", tags + ['error'], { severity: 'ERROR', datetime: Time.now.to_s })
      end
    end
  end
end

namespace :notification do
  require './lib/notification'
  desc 'send allow failure status to slack'
  task :slack_notif do
    Notification.slack_notif
  end
end

# desc 'Default: run specs'
# task test: %i[spec]

# desc 'Run specs'
# RSpec::Core::RakeTask.new(:spec) do |t|
#   t.rspec_opts = '--require ./spec/spec_helper'
#   t.rspec_opts = ["--format", "json", "--out", "UT-OLYMPUS-report_tms.json", "--format", " progress"]
# end
