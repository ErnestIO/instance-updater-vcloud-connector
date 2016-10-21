# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

require_relative 'spec_helper'

describe 'vcloud_instance_updater_microservice' do
  let!(:provider) { double('provider', foo: 'bar') }

  before do
    allow_any_instance_of(Object).to receive(:sleep)
    require_relative '../adapter'
  end

  describe '#update_instance' do
    let!(:data)   do
      {
        datacenter_name: 'r3-acidre',
        datacenter_username: 'acidre@r3labs-development',
        datacenter_password: 'ed7d0a9ffed74b2d3bc88198cbe7948c',
        name: 'instance',
        cpus: '2',
        ram: '512',
        ip: '10.0.0.10',
        disks: [],
        network_name: 'network',
        reference_image: 'centos65-tty-sudo-disabled',
        reference_catalog: 'images'
      }
    end
    let!(:datacenter) { double('datacenter', private_network: true, compute_instance: instance) }
    let!(:vapp)       { double('vapp', isDeployed: true) }
    let!(:instance) do
      double('instance',
             tasks: [],
             name: '',
             power_off: true,
             vapp: vapp,
             'hostname=' => true,
             'cpus=' => true,
             'memory=' => true,
             disks: {},
             nics: [],
             add_nic: true,
             add_disk: true,
             power_on: true)
    end

    before do
      allow_any_instance_of(Provider).to receive(:initialize).and_return(true)
      allow_any_instance_of(Provider).to receive(:datacenter).and_return(datacenter)
      allow_any_instance_of(Provider).to receive(:image).and_return(true)
    end

    it 'update a instance on vcloud' do
      expect(update_instance(data)).to eq 'instance.update.vcloud.done'
    end
  end
end
