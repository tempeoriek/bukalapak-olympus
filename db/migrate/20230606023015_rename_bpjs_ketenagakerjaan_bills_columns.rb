class RenameBpjsKetenagakerjaanBillsColumns < ActiveRecord::Migration[5.2]
  @throttler = Lhm::Throttler::Time.new(stride: 1000)

  def self.up
    Lhm.change_table :bpjs_ketenagakerjaan_bills, throttler: @throttler do |t|
      t.rename_column :jpk, :jkp
      t.rename_column :jpn, :jp
    end
  end

  def self.down
    throttler = Lhm::Throttler::Time.new(stride: 1000)
    Lhm.change_table :bpjs_ketenagakerjaan_bills, throttler: @throttler do |t|
      t.rename_column :jkp, :jpk
      t.rename_column :jp, :jpn
    end
  end
end
