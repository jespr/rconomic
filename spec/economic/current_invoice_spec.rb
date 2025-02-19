require './spec/spec_helper'

describe Economic::CurrentInvoice do
  let(:session) { make_session }
  subject { (i = Economic::CurrentInvoice.new).tap { i.session = session } }

  it "inherits from Economic::Entity" do
    Economic::CurrentInvoice.ancestors.should include(Economic::Entity)
  end

  describe "new" do
    it "initializes lines as an empty proxy" do
      subject.lines.should be_instance_of(Economic::CurrentInvoiceLineProxy)
      subject.lines.should be_empty
    end
  end

  describe ".proxy" do
    it "should return a CurrentInvoiceProxy" do
      subject.proxy.should be_instance_of(Economic::CurrentInvoiceProxy)
    end

    it "should return a proxy owned by session" do
      subject.proxy.session.should == session
    end
  end

  describe "save" do
    context "when successful" do
      before :each do
        savon.stubs('CurrentInvoice_CreateFromData').returns(:success)
      end

      context "when invoice has lines" do
        before :each do
          2.times do
            line = Economic::CurrentInvoiceLine.new
            line.stubs(:save)
            subject.lines << line
          end
        end

        it "adds the lines to the invoice" do
          subject.lines.each do |line|
            line.expects(:invoice=).with(subject)
          end

          subject.save
        end

        it "assigns the invoice session to each line" do
          subject.lines.each do |line|
            line.expects(:session=).with(subject.session)
          end

          subject.save
        end

        it "saves each line" do
          subject.lines.each do |line|
            line.expects(:save)
          end

          subject.save
        end
      end
    end
  end
end
