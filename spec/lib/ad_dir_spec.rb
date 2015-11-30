require 'spec_helper'
require 'ad_dir'

describe AdDir do
  it 'should have a VERSION constant' do
    expect(subject.const_get('VERSION')).not_to be_empty
  end

  context 'running ActiveDirectory' do
    host     = 'magma.test.geo.uzh.ch'
    base     = 'dc=test,dc=geo,dc=uzh,dc=ch'

    context 'valid credentials' do
      username = 'cn=administrator,cn=users,dc=test,dc=geo,dc=uzh,dc=ch'
      password = 'DXB7xfwP4iFfiFet7b'

      it '#establish_connection successes with "true"' do
        expect(
          subject.establish_connection(
            host: host, base: base, username: username,
            password: password)
          ).to be_truthy
      end

      it '#connection should return a connection that binds' do
        expect(subject.connection.bind).to be_truthy
      end
    end

    context 'invalid credentials' do
      username = 'bling'
      password = 'some'
      it '#establish_connection fails with \'false\'' do
        expect(
          subject.establish_connection(
            host: host, base: base,
            username: username, password: password)
          ).to be_falsy
      end
    end
  end

  context 'Wrong connection' do
    host = 'does.not.exist.com'
    it '#establish_connection raises a getaddr error' do
      expect do
        subject.establish_connection(
          host: host, base: 'basd', username: 'chef', password: 'wow')
      end.to raise_error(/getaddrinfo: Name or service not known/)
    end
  end
end
