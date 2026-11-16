# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReceiptBinMailer, type: :mailer do
  describe "#bounce_success" do
    it "lists each transaction a receipt was auto-paired with, linking to it and to reversing the pairing" do
      ledger_item = create(:canonical_pending_transaction, memo: "Donuts", amount_cents: -10_00).local_hcb_code.ledger_item
      receipt = Receipt.new(user: create(:user), receiptable: ledger_item, upload_method: :email_receipt_bin)
      receipt.file.attach(io: File.open(file_fixture("receipt.png")), filename: "receipt.png", content_type: "image/png")
      receipt.save!

      mail = described_class.with(to: "test@example.com", receipts_count: 1, paired_with: [ledger_item]).bounce_success

      html = Nokogiri::HTML(mail.body.decoded)
      expect(html.at_css("a[href='#{ledger_item_url(ledger_item)}']").text).to eq("Donuts")
      expect(html.at_css("a[href='#{hcb_code_url(ledger_item.hcb_code, reverse: receipt.id)}']").text).to eq("click to reverse this pairing")
    end

    it "points at the receipt bin when nothing was paired" do
      mail = described_class.with(to: "test@example.com", receipts_count: 2, paired_with: []).bounce_success

      expect(mail.body.decoded).to include("Receipt Bin")
      expect(mail.body.decoded).not_to include("automatically matched")
    end
  end
end
