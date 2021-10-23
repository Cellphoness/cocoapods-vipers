require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Command::Vipers do
    describe 'CLAide' do
      it 'registers it self' do
        Command.parse(%w{ vipers }).should.be.instance_of Command::Vipers
      end
    end
  end
end

